// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../interfaces/ICore.sol";

abstract contract Core is ICore, Ownable {
    error InvalidMessageType();
    error Forbidden();
    error InvalidStatus();
    error LimitOverflow();
    error LimitUnderflow();

    OwnedERC20 public immutable asset;
    IAdapter public adapter;

    constructor(address owner_, string memory name_, string memory symbol_) Ownable(owner_) {
        asset = new OwnedERC20(name_, symbol_, address(this));
    }

    function setAdapter(address newAdapter) external onlyOwner {
        adapter = IAdapter(newAdapter);
    }

    function receiveMessage(IAdapter.MessageType messageType, bytes calldata message, bytes calldata extraOptions)
        external
        payable
        virtual
    {
        require(msg.sender == address(adapter), "Core: forbidden adapter");
        _receiveMessage(messageType, message, extraOptions);
    }

    function _receiveMessage(IAdapter.MessageType messageType, bytes calldata message, bytes calldata extraOptions)
        internal
        virtual;

    function _sendMessage(
        IAdapter.MessageType messageType,
        bytes memory message,
        bytes memory options,
        bytes memory extraOptions,
        uint256 value
    ) internal {
        adapter.sendMessage{value: value}(messageType, message, options, extraOptions);
    }
}
