// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract RedeemClaimer {
    using SafeERC20 for IERC20;

    error Forbidden();

    address public immutable claimer;
    address public immutable core;
    IERC20 public immutable asset;

    constructor(address claimer_, address core_, address asset_) {
        claimer = claimer_;
        core = core_;
        asset = IERC20(asset_);
    }

    function claimAssets(bytes calldata data) public {
        if (data.length == 0) {
            return;
        }
        bytes memory response = Address.functionCall(claimer, data);
        uint256 balanceBefore = asset.balanceOf(address(this));
        uint256 assets = abi.decode(response, (uint256));
        if (assets == 0 || assets + balanceBefore != asset.balanceOf(address(this))) {
            revert Forbidden();
        }
    }

    function claim(bytes calldata data) external returns (uint256 assets) {
        if (msg.sender != core) {
            revert Forbidden();
        }
        claimAssets(data);
        assets = asset.balanceOf(address(this));
        asset.safeTransfer(core, assets);
    }
}
