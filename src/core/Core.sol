// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../interfaces/ICore.sol";

abstract contract Core is ICore, Ownable {
    error InvalidMessageType();
    error Forbidden();
    error InvalidStatus();
    error LimitOverflow(uint256 targetValue, uint256 value);
    error LimitUnderflow(uint256 targetValue, uint256 value);

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
        if (msg.sender != address(adapter)) {
            revert Forbidden();
        }
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
        bytes memory fullMessage = adapter.encodeMessage(messageType, message, extraOptions);
        uint256 requiredValue = adapter.quoteMessage(messageType, fullMessage, options);

        if (requiredValue > value) {
            revert LimitOverflow(requiredValue, value);
        }

        adapter.sendMessage{value: value}(messageType, fullMessage, options, extraOptions);
    }

    receive() external payable {}
}
