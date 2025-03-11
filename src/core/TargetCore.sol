// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../interfaces/core/ITargetCore.sol";
import "./TargetCoreStorage.sol";

contract TargetCore is ITargetCore, TargetCoreStorage {
    using SafeERC20 for IERC20;

    address private immutable _deployer;

    constructor() {
        _disableInitializers();
        _deployer = _msgSender();
    }

    /// @inheritdoc ITargetCore
    function initialize(InitParams calldata params) external initializer {
        if (_msgSender() != _deployer) {
            revert("TargetCore: not deployer");
        }
        __TargetCoreStorage_init(params);
    }

    /// @inheritdoc ITargetCore
    function deposit(uint256 assets) external onlyRole(DEPOSIT_ROLE) {
        IMellowOFT oft_ = oft();
        IERC4626 vault_ = vault();
        IERC20(oft_).safeIncreaseAllowance(address(vault_), assets);
        vault_.deposit(assets, address(this));
        IERC20(oft_).forceApprove(address(vault_), 0);
        emit Deposit(assets);
    }

    /// @inheritdoc ITargetCore
    function redeem(uint256 shares) external onlyRole(REDEEM_ROLE) {
        vault().redeem(shares, address(this), address(this));
        emit Redeem(shares);
    }

    /// @inheritdoc ITargetCore
    function claim(bytes calldata data) external onlyRole(CLAIM_ROLE) {
        IMellowOFT oft_ = oft();
        uint256 balanceBefore = oft_.balanceOf(address(this));
        bytes memory response = Address.functionCall(claimer(), data);
        if (response.length != 32) {
            revert("TargetCore: invalid response");
        }
        uint256 expectedAssets = abi.decode(response, (uint256));
        uint256 balanceAfter = oft_.balanceOf(address(this));
        if (expectedAssets == 0 || balanceAfter != balanceBefore + expectedAssets) {
            revert("TargetCore: claim failed");
        }
        emit Claim(expectedAssets, data);
    }

    /// @inheritdoc ITargetCore
    function pushToSource(uint256 assets) external payable onlyRole(PUSH_ROLE) {
        IMellowOFT oft_ = oft();
        assets = oft_.removeDust(assets);
        uint256 liquid = oft_.balanceOf(address(this));
        if (assets > liquid) {
            revert("TargetCore: insufficient assets");
        }
        if (assets == 0) {
            return;
        }
        (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt) = oft_.send{value: msg.value}(
            SendParam(sourceEndpointId(), sourceCoreAddress(), assets, assets, new bytes(0), new bytes(0), new bytes(0)),
            MessagingFee(msg.value, 0),
            _msgSender()
        );
        emit PushToSource(assets, msgReceipt, oftReceipt);
    }
}
