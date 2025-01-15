// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../interfaces/ICore.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IClaimer {
    function multiAcceptAndClaim(
        address multiVault,
        uint256[] calldata subvaultIndices,
        uint256[][] calldata indices,
        address recipient,
        uint256 maxAssets
    ) external returns (uint256 assets);
}

contract RedeemClaimer {
    using SafeERC20 for IERC20;

    error Forbidden();

    address public immutable claimer;
    address public immutable owner;
    IERC20 public immutable asset;

    constructor(address claimer_, address owner_) {
        claimer = claimer_;
        owner = owner_;
        asset = IERC20(ICore(owner_).asset());
    }

    function claim(address multiVault, bytes calldata data) external returns (uint256 assets) {
        if (msg.sender != owner) {
            revert Forbidden();
        }
        (uint256[] memory subvaultIndices, uint256[][] memory indices, uint256 maxAssets) =
            abi.decode(data, (uint256[], uint256[][], uint256));
        IClaimer(claimer).multiAcceptAndClaim(multiVault, subvaultIndices, indices, address(this), maxAssets);
        assets = asset.balanceOf(address(this));
        asset.safeTransfer(owner, assets);
    }
}
