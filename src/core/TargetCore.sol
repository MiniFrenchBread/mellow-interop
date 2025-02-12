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
    RedeemClaimer public redeemClaimerSingleton;

    /// @inheritdoc ITargetCore
    mapping(uint256 batchId => uint256) public depositBatchShares;
    /// @inheritdoc ITargetCore
    mapping(uint256 batchId => uint256) public depositBatchAssets;
    /// @inheritdoc ITargetCore
    mapping(uint256 batchId => bool) public isDepositBatchReceived;

    /// @inheritdoc ITargetCore
    mapping(uint256 batchId => address) public redeemClaimers;
    /// @inheritdoc ITargetCore
    mapping(uint256 batchId => uint256) public redeemBatchShares;
    /// @inheritdoc ITargetCore
    mapping(uint256 batchId => bool) public isRedeemBatchReceived;

    /// @inheritdoc ITargetCore
    mapping(uint256 batchId => uint256) public claimBatchCount;
    /// @inheritdoc ITargetCore
    mapping(uint256 batchId => mapping(uint256 index => uint256 assets)) public claimBatchAssets;
    /// @inheritdoc ITargetCore
    mapping(uint256 index => uint256 assets) public slashingRequestsAt;
    /// @inheritdoc ITargetCore
    uint256 public slashingRequests = 0;

    constructor(bytes32 name_, uint256 version_) CoreStorage(name_, version_) {
        _disableInitializers();
    }

    /// @inheritdoc ITargetCore
    function initialize(
        address admin_,
        address vault_,
        address adapter_,
        address claimer_,
        string memory name_,
        string memory symbol_
    ) external initializer {
        __init_Core(admin_, adapter_, name_, symbol_);
        redeemClaimerSingleton = new RedeemClaimer(claimer_, address(this), address(asset()));
        vault = vault_;
    }

    function _receiveMessage(IAdapter.MessageType messageType, bytes calldata message) internal virtual override {
        (uint256 batchId, uint256 amount) = abi.decode(message, (uint256, uint256));
        if (messageType == IAdapter.MessageType.DEPOSIT) {
            if (!isDepositBatchReceived[batchId]) {
                isDepositBatchReceived[batchId] = true;
                depositBatchAssets[batchId] = amount;
            }
        } else if (messageType == IAdapter.MessageType.REDEEM) {
            if (!isRedeemBatchReceived[batchId]) {
                isRedeemBatchReceived[batchId] = true;
                redeemBatchShares[batchId] = amount;
            }
        } else {
            revert InvalidMessageType();
        }
    }

    /// @inheritdoc ITargetCore
    function rejectRedeemBatch(uint256 batchId) external payable atLeastOperator {
        if (!isRedeemBatchReceived[batchId] || redeemClaimers[batchId] != address(0)) {
            revert Forbidden();
        }
        _sendMessage(IAdapter.MessageType.REJECT, abi.encode(getId(IAdapter.MessageType.REDEEM, batchId)), msg.value);
        emit RedeemBatchRejected(batchId, msg.value);
    }

    /// @inheritdoc ITargetCore
    function claim(uint256 batchId, bytes calldata data) external payable atLeastOperator returns (uint256 assets) {
        if (!isRedeemBatchReceived[batchId]) {
            revert Forbidden();
        }

        address claimer = redeemClaimers[batchId];
        if (claimer == address(0)) {
            claimer = Clones.cloneDeterministic(address(redeemClaimerSingleton), bytes32(batchId));
            redeemClaimers[batchId] = address(claimer);
            IERC4626(vault).redeem(redeemBatchShares[batchId], address(claimer), address(this));
        }
        assets = RedeemClaimer(claimer).claim(data);
        if (assets != 0) {
            asset().burn(address(this), assets);
            uint256 index = claimBatchCount[batchId]++;
            claimBatchAssets[batchId][index] = assets;
            _sendMessage(IAdapter.MessageType.CLAIM, abi.encode(batchId, index, assets), msg.value);
            emit Claim(batchId, index, assets);
        }
    }

    /// @inheritdoc ITargetCore
    function retryClaim(uint256 batchId, uint256 index) external payable atLeastOperator {
        uint256 assets = claimBatchAssets[batchId][index];
        if (assets == 0) {
            revert Forbidden();
        }
        _sendMessage(IAdapter.MessageType.CLAIM, abi.encode(batchId, index, assets), msg.value);
        emit ClaimRetried(batchId, index, assets);
    }

    /// @inheritdoc ITargetCore
    function rejectDepositBatch(uint256 batchId) external payable atLeastOperator {
        if (!isDepositBatchReceived[batchId] || depositBatchAssets[batchId] == 0) {
            revert Forbidden();
        }
        _sendMessage(IAdapter.MessageType.REJECT, abi.encode(getId(IAdapter.MessageType.DEPOSIT, batchId)), msg.value);
        emit DepositBatchRejected(batchId, msg.value);
    }

    /// @inheritdoc ITargetCore
    function pushDepositBatch(uint256 batchId) external payable atLeastOperator {
        if (!isDepositBatchReceived[batchId]) {
            revert Forbidden();
        }
        uint256 assets = depositBatchAssets[batchId];
        if (assets == 0) {
            return;
        }
        delete depositBatchAssets[batchId];
        OwnedERC20 asset_ = asset();
        asset_.mint(address(this), assets);
        IERC20(asset_).safeIncreaseAllowance(vault, assets);
        uint256 shares = IERC4626(vault).deposit(assets, address(this));
        depositBatchShares[batchId] = shares;

        _sendMessage(IAdapter.MessageType.DEPOSIT, abi.encode(batchId, shares), msg.value);
        emit DepositBatchPushed(batchId, shares, msg.value);
    }

    /// @inheritdoc ITargetCore
    function retryPushDepositBatch(uint256 batchId) external payable atLeastOperator {
        uint256 shares = depositBatchShares[batchId];
        if (shares == 0) {
            revert Forbidden();
        }
        _sendMessage(IAdapter.MessageType.DEPOSIT, abi.encode(batchId, shares), msg.value);
        emit DepositBatchPushed(batchId, shares, msg.value);
    }

    /// @inheritdoc ITargetCore
    function slash(uint256 assets) external payable onlyRole(BURNER_ROLE) {
        asset().burn(_msgSender(), assets);
        uint256 index = slashingRequests++;
        slashingRequestsAt[index] = assets;
        emit SlashingRequested(index, assets);
    }

    /// @inheritdoc ITargetCore
    function pushSlashing(uint256 index) external payable atLeastOperator {
        uint256 assets = slashingRequestsAt[index];
        if (assets == 0) {
            revert Forbidden();
        }
        _sendMessage(IAdapter.MessageType.SLASHING, abi.encode(index, assets), msg.value);
        emit SlashingPushed(index, assets);
    }
}
