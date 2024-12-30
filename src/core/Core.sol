// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../adapters/IAdapter.sol";
import "../utils/OwnedERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Core is Ownable {
    OwnedERC20 public immutable asset;
    IAdapter public adapter;

    bytes32 public pairedChainId;
    bytes32 public pairedCoreAddress;
    bytes32 public pairedCoreAdapterAddress;

    constructor(address owner_, string memory name_, string memory symbol_) Ownable(owner_) {
        asset = new OwnedERC20(name_, symbol_, address(this));
    }

    function setAdapter(address newAdapter) external onlyOwner {
        adapter = IAdapter(newAdapter);
    }

    function receiveMessage(bytes32 chainId, bytes32 sender, uint256 value, bytes calldata data)
        external
        payable
        virtual
    {
        require(msg.sender == address(adapter), "BaseCore: forbidden adapter");
        require(chainId == pairedChainId, "BaseCore: wrong chain id");
        require(sender == pairedCoreAdapterAddress, "BaseCore: wrong sender");
        _receiveMessage(value, data);
    }

    function _receiveMessage(uint256 value, bytes memory data) internal virtual;

    function _sendMessage(uint256 value, bytes memory data) internal virtual;
}
