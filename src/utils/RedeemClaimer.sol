// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../interfaces/IClaimer.sol";
import "../interfaces/ITargetCore.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract RedeemClaimer {
    using SafeERC20 for IERC20;

    error Forbidden();

    IClaimer public immutable claimer;
    ITargetCore public immutable core;
    IERC20 public immutable asset;

    constructor(address claimer_, address core_, address asset_) {
        claimer = IClaimer(claimer_);
        core = ITargetCore(core_);
        asset = IERC20(asset_);
    }

    function claimAssets(bytes calldata data) public {
        (uint256[] memory subvaultIndices, uint256[][] memory indices, uint256 maxAssets) =
            abi.decode(data, (uint256[], uint256[][], uint256));
        claimer.multiAcceptAndClaim(core.vault(), subvaultIndices, indices, address(this), maxAssets);
    }

    function claim(bytes calldata data) external returns (uint256 assets) {
        if (msg.sender != address(core)) {
            revert Forbidden();
        }
        claimAssets(data);
        assets = asset.balanceOf(address(this));
        asset.safeTransfer(address(core), assets);
    }
}
