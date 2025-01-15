// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

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
    address public immutable claimer;
    address public immutable owner;

    constructor(address claimer_, address owner_) {
        claimer = claimer_;
        owner = owner_;
    }

    function claim(address multiVault, bytes calldata data) external returns (uint256 assets) {
        require(msg.sender == owner, "RedeemClaimer: forbidden");
        (uint256[] memory subvaultIndices, uint256[][] memory indices, uint256 maxAssets) =
            abi.decode(data, (uint256[], uint256[][], uint256));
        return IClaimer(claimer).multiAcceptAndClaim(multiVault, subvaultIndices, indices, owner, maxAssets);
    }
}
