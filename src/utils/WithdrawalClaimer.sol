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

contract WithdrawalClaimer {
    address public immutable claimer;
    address public immutable owner;

    constructor(address claimer_, address owner_) {
        claimer = claimer_;
        owner = owner_;
    }

    function claim(
        address multiVault,
        uint256[] calldata subvaultIndices,
        uint256[][] calldata indices,
        uint256 maxAssets
    ) external returns (uint256 assets) {
        require(msg.sender == owner, "WithdrawalClaimer: forbidden");
        return IClaimer(claimer).multiAcceptAndClaim(multiVault, subvaultIndices, indices, owner, maxAssets);
    }
}
