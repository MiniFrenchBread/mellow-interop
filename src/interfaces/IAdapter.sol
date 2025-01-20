// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "./ICore.sol";

interface IAdapter {
    enum MessageType {
        DEPOSIT,
        REDEEM,
        CLAIM,
        SLASHING,
        RETRY_DEPOSIT,
        RETRY_REDEEM,
        RETRY_CLAIM,
        RETRY_SLASHING
    }

    function core() external view returns (ICore);

    function sendMessage(
        MessageType messageType,
        bytes calldata message,
        bytes calldata options,
        bytes calldata extraOptions
    ) external payable;

    function encodeMessage(MessageType messageType, bytes calldata message, bytes calldata extraOptions)
        external
        view
        returns (bytes memory);

    function decodeMessage(bytes calldata message) external view returns (MessageType, bytes memory, bytes memory);

    function quoteMessage(MessageType messageType, bytes calldata message, bytes calldata options)
        external
        view
        returns (uint256 nativeFee);
}
