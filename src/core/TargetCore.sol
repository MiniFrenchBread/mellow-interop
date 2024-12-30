// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "./Core.sol";

abstract contract TargetCore is Core {
// address public immutable vault;

// constructor(address owner_, address vault_) Ownable(owner_) {
//     vault = vault_;
// }

// function _receiveMessage(bytes32 chainId, bytes32 sender, uint256 value, bytes calldata data)
//     internal
//     virtual
//     override
// {}

// function _sendMessage(bytes32 chainId, bytes32 receiver, uint256 value, bytes calldata data)
//     internal
//     virtual
//     override
// {}

// function _deposit(uint256 assets, uint256 batchId) internal returns (uint256 shares) {

//     return IERC4626(vault).deposit(
//         assets,
//         batchId,
//         address(this)
//     );
// }

// mapping(uint256 batchId => address claimer) public withdrawalClaimers;

// function _withdraw(uint256 shares, uint256 batchId) internal returns (uint256 instant, uint256 pending) {

// }

// function _claim(uint256 batchId) internal returns (uint256 assets) {}

// function claim(uint256 batchId, ) external payable returns (uint256 assets) {
//     return _claim(batchId);
// }
}
