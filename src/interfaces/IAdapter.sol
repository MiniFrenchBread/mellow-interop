// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "./ICore.sol";

interface IAdapter {
    enum MessageType {
        DEPOSIT,
        REDEEM,
        CLAIM,
        SLASHING,
        REJECT
    }

    function core() external view returns (ICore);

    function gasReceiver() external view returns (address);

    function sendMessage(MessageType messageType, bytes calldata message, bytes calldata options) external payable;

    function encodeMessage(MessageType messageType, bytes calldata message) external view returns (bytes memory);

    function decodeMessage(bytes calldata message) external view returns (MessageType, bytes memory);

    function quoteMessage(MessageType messageType, bytes calldata message, bytes calldata options)
        external
        view
        returns (uint256 nativeFee);
}
