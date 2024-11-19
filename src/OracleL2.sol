// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.25;

import {IOracleL2} from "./interfaces/IOracleL2.sol";
import {OAppCore} from "@layerzero-v2/oapp/OAppCore.sol";
import {OAppReceiver} from "@layerzero-v2/oapp/OAppReceiver.sol";
import {Origin} from "@layerzero-v2/oapp/interfaces/IOAppReceiver.sol";
import {OFT} from "@layerzero-v2/oft/OFT.sol";

contract OracleL2 is OAppReceiver, IOracleL2 {
    address public immutable transmitter;
    uint256 public ratioX96;

    constructor(address _lzEndpoint, address _delegate, address _transmitter)
        OAppCore(_lzEndpoint, _delegate)
    {
        transmitter = _transmitter;
    }

    /**
     * @dev Receives message from L1 to update ratioX96
     * @param _origin The origin information containing the source endpoint and sender address.
     *  - srcEid: The source chain endpoint ID.
     *  - sender: The sender address on the src chain.
     *  - nonce: The nonce of the message.
     * @param _guid The unique identifier for the received LayerZero message.
     * @param _message The payload of the received message.
     * @param _executor The address of the executor for the received message.
     * @param _extraData Additional arbitrary data provided by the corresponding executor.
     */
    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) internal virtual override {
        require(address(uint160(uint256(_origin.sender))) == transmitter);
        ratioX96 = abi.decode(_message, (uint256));
    }
}
