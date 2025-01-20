// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../interfaces/IClaimer.sol";
import "../interfaces/ICore.sol";
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

    function claim(address multiVault, bytes calldata data) external returns (uint256 assets) {
        if (msg.sender != core) {
            revert Forbidden();
        }
        (uint256[] memory subvaultIndices, uint256[][] memory indices, uint256 maxAssets) =
            abi.decode(data, (uint256[], uint256[][], uint256));
        IClaimer(claimer).multiAcceptAndClaim(multiVault, subvaultIndices, indices, address(this), maxAssets);
        assets = asset.balanceOf(address(this));
        asset.safeTransfer(core, assets);
    }
}
