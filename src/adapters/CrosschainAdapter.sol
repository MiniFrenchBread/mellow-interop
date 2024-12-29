// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract CrosschainAdapter is Ownable {
    mapping(address adapter => bool isApproved) public approvedAdapters;

    function receiveMessage(bytes32 chainId, bytes32 sender, uint256 value, bytes calldata data)
        external
        payable
        virtual
    {
        require(approvedAdapters[msg.sender], "CrosschainAdapter: forbidden adapter");
        _receiveMessage(chainId, sender, value, data);
    }

    function _receiveMessage(bytes32 chainId, bytes32 sender, uint256 value, bytes calldata data) internal virtual;

    function _sendMessage(bytes32 chainId, bytes32 receiver, uint256 value, bytes calldata data) internal virtual;
}
