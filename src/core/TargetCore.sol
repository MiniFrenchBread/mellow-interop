// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../utils/RedeemClaimer.sol";
import "./Core.sol";
import "@openzeppelin/contracts/interfaces/IERC4626.sol";

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract TargetCore is Core {
    using SafeERC20 for IERC20;

    address public immutable vault;
    RedeemClaimer public immutable claimerSingleton;

    address public burner;
    mapping(uint256 batchId => address) public claimers;

    mapping(uint256 batchId => bool) public isDepositBatchCompleted;
    mapping(uint256 batchId => uint256) public depositBatchShares;

    mapping(uint256 batchId => bool) public isRedeemBatchCompleted;

    mapping(uint256 batchId => uint256) public claimsCount;
    mapping(uint256 batchId => mapping(uint256 index => uint256 assets)) public claims;

    mapping(uint256 index => uint256 assets) public slashing;
    uint256 public slashings = 0;

    constructor(address owner_, address vault_, address claimer_, string memory name_, string memory symbol_)
        Core(owner_, name_, symbol_)
    {
        vault = vault_;
        claimerSingleton = new RedeemClaimer(claimer_, address(this));
    }

    function setBurner(address burner_) external onlyOwner {
        /// @dev vault, separate burner contract or zero address
        burner = burner_;
    }

    function _receiveMessage(IAdapter.MessageType messageType, bytes calldata message, bytes calldata extraOptions)
        internal
        virtual
        override
    {
        (uint256 batchId, uint256 amount) = abi.decode(message, (uint256, uint256));
        if (messageType == IAdapter.MessageType.DEPOSIT || messageType == IAdapter.MessageType.RETRY_DEPOSIT) {
            if (isDepositBatchCompleted[batchId]) {
                if (messageType != IAdapter.MessageType.RETRY_DEPOSIT) {
                    revert InvalidMessageType();
                }
                _sendMessage(
                    IAdapter.MessageType.DEPOSIT,
                    abi.encode(batchId, depositBatchShares[batchId]),
                    extraOptions,
                    new bytes(0),
                    msg.value
                );
            }

            asset.mint(address(this), amount);
            IERC20(asset).safeIncreaseAllowance(vault, amount);
            uint256 shares = IERC4626(vault).deposit(amount, address(this));
            _sendMessage(
                IAdapter.MessageType.DEPOSIT, abi.encode(batchId, shares), extraOptions, new bytes(0), msg.value
            );
            isDepositBatchCompleted[batchId] = true;
            depositBatchShares[batchId] = shares;
        } else if (messageType == IAdapter.MessageType.REDEEM || messageType == IAdapter.MessageType.RETRY_REDEEM) {
            if (isRedeemBatchCompleted[batchId]) {
                if (messageType != IAdapter.MessageType.RETRY_REDEEM) {
                    revert InvalidMessageType();
                }
                return;
            }
            address claimer = Clones.cloneDeterministic(address(claimerSingleton), bytes32(batchId));
            claimers[batchId] = address(claimer);
            IERC4626(vault).redeem(amount, address(claimer), address(this));
            isRedeemBatchCompleted[batchId] = true;
        } else {
            revert InvalidMessageType();
        }
    }

    // NOTE: permissionless claim
    function claim(uint256 batchId, bytes calldata data, bytes calldata options)
        external
        payable
        returns (uint256 assets)
    {
        address claimer = claimers[batchId];
        if (claimer == address(0)) {
            revert Forbidden();
        }
        assets = RedeemClaimer(claimer).claim(vault, data);
        asset.burn(address(this), assets);
        if (assets == 0) {
            revert Forbidden();
        }
        uint256 index = claimsCount[batchId]++;
        claims[batchId][index] = assets;
        _sendMessage(IAdapter.MessageType.CLAIM, abi.encode(batchId, index, assets), options, new bytes(0), msg.value);
    }

    function retryClaim(uint256 batchId, uint256 index, bytes calldata options) external payable {
        address claimer = claimers[batchId];
        if (claimer == address(0)) {
            revert Forbidden();
        }
        uint256 assets = claims[batchId][index];
        if (assets == 0) {
            revert Forbidden();
        }
        _sendMessage(IAdapter.MessageType.RETRY_CLAIM, abi.encode(batchId, assets), options, new bytes(0), msg.value);
    }

    function slash(uint256 assets, bytes calldata options) external payable {
        if (msg.sender != burner) {
            revert Forbidden();
        }
        asset.burn(burner, assets);
        uint256 index = slashings++;
        slashing[index] = assets;
        _sendMessage(IAdapter.MessageType.SLASHING, abi.encode(index, assets), options, new bytes(0), msg.value);
    }

    /// @dev permissionless function
    function retrySlash(uint256 index, bytes calldata options) external payable {
        uint256 assets = slashing[index];
        if (assets == 0) {
            revert Forbidden();
        }
        _sendMessage(IAdapter.MessageType.SLASHING, abi.encode(index, assets), options, new bytes(0), msg.value);
    }
}
