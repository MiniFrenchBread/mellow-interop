// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../interfaces/ITargetCore.sol";
import "../utils/RedeemClaimer.sol";
import "./Core.sol";

contract TargetCore is ITargetCore, Core {
    using SafeERC20 for IERC20;

    /// @inheritdoc ITargetCore
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /// @inheritdoc ITargetCore
    address public vault;
    /// @inheritdoc ITargetCore
    RedeemClaimer public claimerSingleton;

    /// @inheritdoc ITargetCore
    address public burner;
    /// @inheritdoc ITargetCore
    mapping(uint256 batchId => address) public claimers;

    /// @inheritdoc ITargetCore
    mapping(uint256 batchId => bool) public isDepositBatchCompleted;
    /// @inheritdoc ITargetCore
    mapping(uint256 batchId => uint256) public depositBatchShares;
    /// @inheritdoc ITargetCore
    mapping(uint256 batchId => uint256) public depositBatchValues;

    /// @inheritdoc ITargetCore
    mapping(uint256 batchId => bool) public isRedeemBatchCompleted;

    /// @inheritdoc ITargetCore
    mapping(uint256 batchId => uint256) public claimsCount;
    /// @inheritdoc ITargetCore
    mapping(uint256 batchId => mapping(uint256 index => uint256 assets)) public claims;

    /// @inheritdoc ITargetCore
    mapping(uint256 index => uint256 assets) public slashing;
    /// @inheritdoc ITargetCore
    uint256 public slashings = 0;

    constructor(bytes32 name_, uint256 version_) CoreStorage(name_, version_) {}

    /// @inheritdoc ITargetCore
    function initialize(
        address admin_,
        address vault_,
        address burner_,
        address adapter_,
        address claimer_,
        string memory name_,
        string memory symbol_
    ) external initializer {
        __init_Core(admin_, adapter_, name_, symbol_);
        __init_TargetCore(vault_, burner_);
        claimerSingleton = new RedeemClaimer(claimer_, address(this), address(asset()));
    }

    /// @inheritdoc ITargetCore
    function setBurner(address burner_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        /// @dev vault, separate burner contract or zero address
        burner = burner_;
    }

    function _receiveMessage(IAdapter.MessageType messageType, bytes calldata message) internal virtual override {
        (uint256 batchId, uint256 amount) = abi.decode(message, (uint256, uint256));
        if (messageType == IAdapter.MessageType.DEPOSIT || messageType == IAdapter.MessageType.RETRY_DEPOSIT) {
            if (isDepositBatchCompleted[batchId]) {
                if (messageType != IAdapter.MessageType.RETRY_DEPOSIT) {
                    revert InvalidMessageType();
                }
                return;
            }

            OwnedERC20 asset_ = asset();
            asset_.mint(address(this), amount);
            IERC20(asset_).safeIncreaseAllowance(vault, amount);
            isDepositBatchCompleted[batchId] = true;
            depositBatchValues[batchId] = msg.value;
            depositBatchShares[batchId] = IERC4626(vault).deposit(amount, address(this));
        } else if (messageType == IAdapter.MessageType.REDEEM || messageType == IAdapter.MessageType.RETRY_REDEEM) {
            if (isRedeemBatchCompleted[batchId]) {
                if (messageType != IAdapter.MessageType.RETRY_REDEEM) {
                    revert InvalidMessageType();
                }
                return;
            }
            address claimer = Clones.cloneDeterministic(address(claimerSingleton), bytes32(batchId));
            claimers[batchId] = address(claimer);
            isRedeemBatchCompleted[batchId] = true;
            IERC4626(vault).redeem(amount, address(claimer), address(this));
        } else {
            revert InvalidMessageType();
        }
    }

    /// @inheritdoc ITargetCore
    function claim(uint256 batchId, bytes calldata data)
        external
        payable
        onlyRole(OPERATOR_ROLE)
        returns (uint256 assets)
    {
        address claimer = claimers[batchId];
        if (claimer == address(0)) {
            revert Forbidden();
        }
        assets = RedeemClaimer(claimer).claim(data);
        asset().burn(address(this), assets);
        if (assets == 0) {
            revert Forbidden();
        }
        uint256 index = claimsCount[batchId]++;
        claims[batchId][index] = assets;
        _sendMessage(IAdapter.MessageType.CLAIM, abi.encode(batchId, index, assets), msg.value);
    }

    /// @inheritdoc ITargetCore
    function retryClaim(uint256 batchId, uint256 index) external payable onlyRole(OPERATOR_ROLE) {
        address claimer = claimers[batchId];
        if (claimer == address(0)) {
            revert Forbidden();
        }
        uint256 assets = claims[batchId][index];
        if (assets == 0) {
            revert Forbidden();
        }
        _sendMessage(IAdapter.MessageType.RETRY_CLAIM, abi.encode(batchId, index, assets), msg.value);
    }

    /// @inheritdoc ITargetCore
    function pushDeposit(uint256 batchId) external payable onlyRole(OPERATOR_ROLE) {
        uint256 shares = depositBatchShares[batchId];
        if (shares == 0) {
            revert Forbidden();
        }
        uint256 value = depositBatchValues[batchId];
        if (value != 0) {
            delete depositBatchValues[batchId];
        }
        _sendMessage(IAdapter.MessageType.DEPOSIT, abi.encode(batchId, shares), msg.value + value);
    }

    /// @inheritdoc ITargetCore
    function retryClaim(uint256 batchId) external payable onlyRole(OPERATOR_ROLE) {
        uint256 shares = depositBatchShares[batchId];
        if (shares == 0) {
            revert Forbidden();
        }
        uint256 value = depositBatchValues[batchId];
        if (value != 0) {
            delete depositBatchValues[batchId];
        }
        _sendMessage(IAdapter.MessageType.DEPOSIT, abi.encode(batchId, shares), msg.value + value);
    }

    /// @inheritdoc ITargetCore
    function slash(uint256 assets) external payable onlyRole(BURNER_ROLE) {
        asset().burn(_msgSender(), assets);
        uint256 index = slashings++;
        slashing[index] = assets;
        _sendMessage(IAdapter.MessageType.SLASHING, abi.encode(index, assets), msg.value);
    }

    /// @inheritdoc ITargetCore
    function retrySlash(uint256 index) external payable onlyRole(OPERATOR_ROLE) {
        uint256 assets = slashing[index];
        if (assets == 0) {
            revert Forbidden();
        }
        _sendMessage(IAdapter.MessageType.RETRY_SLASHING, abi.encode(index, assets), msg.value);
    }

    function __init_TargetCore(address vault_, address burner_) internal onlyInitializing {
        vault = vault_;
        burner = burner_;
    }
}
