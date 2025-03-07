// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import {MellowOFT} from "../oft/MellowOFT.sol";
import {TargetCoreStorage} from "./TargetCoreStorage.sol";
import {MessagingFee, SendParam} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract TargetCore is TargetCoreStorage {
    using SafeERC20 for IERC20;

    constructor() {
        _disableInitializers();
    }

    function initialize(InitParams calldata params) external initializer {
        __TargetCoreStorage_init(params);
    }

    function deposit(uint256 assets) external onlyRole(DEPOSIT_ROLE) {
        MellowOFT oft_ = oft();
        IERC4626 vault_ = vault();
        IERC20(oft_).safeIncreaseAllowance(address(vault_), assets);
        vault_.deposit(assets, address(this));
        IERC20(oft_).forceApprove(address(vault_), 0);
    }

    function redeem(uint256 shares) external onlyRole(REDEEM_ROLE) {
        vault().redeem(shares, address(this), address(this));
    }

    function claim(bytes calldata data) external onlyRole(CLAIM_ROLE) {
        MellowOFT oft_ = oft();
        uint256 balanceBefore = oft_.balanceOf(address(this));
        bytes memory response = Address.functionCall(claimer(), data);
        require(response.length == 32, "TargetCore: invalid response");
        uint256 expectedAssets = abi.decode(response, (uint256));
        uint256 balanceAfter = oft_.balanceOf(address(this));
        require(expectedAssets > 0 && balanceAfter == balanceBefore + expectedAssets, "TargetCore: claim failed");
    }

    function pushToSource(uint256 assets) external payable onlyRole(PUSH_ROLE) {
        MellowOFT oft_ = oft();
        assets = oft_.removeDust(assets);
        uint256 liquid = oft_.balanceOf(address(this));
        if (assets < liquid) {
            revert("TargetCore: insufficient assets");
        }
        if (assets == 0) {
            return;
        }
        oft().send{value: msg.value}(
            SendParam(sourceEndpointId(), sourceCoreAddress(), assets, assets, new bytes(0), new bytes(0), new bytes(0)),
            MessagingFee(msg.value, 0),
            _msgSender()
        );
    }
}
