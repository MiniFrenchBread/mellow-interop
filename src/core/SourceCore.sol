// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import "../interfaces/core/ISourceCore.sol";
import "./SourceCoreStorage.sol";

contract SourceCore is ISourceCore, SourceCoreStorage {
    using SafeERC20 for IERC20;

    address private immutable _deployer;

    constructor() {
        _disableInitializers();
        _deployer = _msgSender();
    }

    modifier handleEpoch() {
        withdrawalQueue().handleEpoch();
        _;
    }

    /// @inheritdoc IERC4626
    function totalAssets() public view override(IERC4626, ERC4626Upgradeable) returns (uint256) {
        return Math.mulDiv(totalSupply(), oracle().getValue(), D18);
    }

    /// @inheritdoc ISourceCore
    function initialize(InitParams calldata params) external initializer {
        if (_msgSender() != _deployer) {
            revert("SourceCore: not deployer");
        }
        __SourceCoreStorage_init(params);
    }

    /// @inheritdoc IERC4626
    function maxMint(address account) public view virtual override(ERC4626Upgradeable, IERC4626) returns (uint256) {
        uint256 assets = maxDeposit(account);
        if (assets == type(uint256).max) {
            return type(uint256).max;
        }
        return convertToShares(assets);
    }

    /// @inheritdoc IERC4626
    function maxDeposit(address) public view virtual override(ERC4626Upgradeable, IERC4626) returns (uint256) {
        uint256 limit_ = limit();
        if (limit_ == type(uint256).max) {
            return type(uint256).max;
        }
        uint256 assets_ = totalAssets();
        return limit_ >= assets_ ? limit_ - assets_ : 0;
    }

    /// @inheritdoc IERC4626
    function deposit(uint256 assets, address receiver)
        public
        override(IERC4626, ERC4626Upgradeable)
        nonReentrant
        handleEpoch
        returns (uint256)
    {
        return super.deposit(assets, receiver);
    }

    /// @inheritdoc IERC4626
    function mint(uint256 shares, address receiver)
        public
        override(IERC4626, ERC4626Upgradeable)
        nonReentrant
        handleEpoch
        returns (uint256)
    {
        return super.mint(shares, receiver);
    }

    /// @inheritdoc ISourceCore
    function requestWithdrawal(uint256 shares) external nonReentrant handleEpoch {
        if (shares == 0) {
            revert("SourceCore: zero shares");
        }
        address caller = _msgSender();
        _transfer(caller, address(withdrawalQueue()), shares);
        withdrawalQueue().request(caller, shares);
        emit WithdrawalRequested(caller, shares);
    }

    /// @inheritdoc ISourceCore
    function pushToTarget() external payable nonReentrant handleEpoch onlyRole(PUSH_ROLE) returns (uint256 assets) {
        IERC20 asset_ = IERC20(asset());
        uint256 liquid = asset_.balanceOf(address(this));
        uint256 pendingShares = withdrawalQueue().totalShares();
        if (pendingShares != 0) {
            uint256 pending = previewRedeem(pendingShares);
            if (pending >= liquid) {
                return 0;
            }
            liquid -= pending;
        }
        IMellowOFTAdapter adapter_ = oftAdapter();
        assets = adapter_.removeDust(liquid);
        if (assets == 0) {
            return 0;
        }
        asset_.safeIncreaseAllowance(address(adapter_), assets);
        (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt) = adapter_.send{value: msg.value}(
            SendParam(targetEndpointId(), targetCoreAddress(), assets, assets, new bytes(0), new bytes(0), new bytes(0)),
            MessagingFee(msg.value, 0),
            _msgSender()
        );
        asset_.forceApprove(address(adapter_), 0);
        emit PushToTarget(assets, msgReceipt, oftReceipt);
    }

    /// @inheritdoc ISourceCore
    function pull(uint256 shares, uint256 assets) external {
        address caller = _msgSender();
        if (caller != address(withdrawalQueue())) {
            revert("SourceCore: only withdrawalQueue can pull");
        }
        _burn(caller, shares);
        IERC20(asset()).safeTransfer(caller, assets);
        emit Pull(caller, shares, assets);
    }

    function _withdraw(address, address, address, uint256, uint256) internal pure override {
        revert("SourceCore: not implemented");
    }
}
