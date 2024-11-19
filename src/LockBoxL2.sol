// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.25;
import {OAppSender} from "@layerzero-v2/oapp/OAppSender.sol";
import {OAppCore} from "@layerzero-v2/oapp/OAppCore.sol";

contract LockBoxL2 is OAppSender {
    address public immutable underlying;

    constructor(address _lzEndpoint, address _delegate, address _underlying)
        OAppCore(_lzEndpoint, _delegate)
    {
        underlying = _underlying;
    }

    // send cross-chain to Transmitter
    function sendToL1() external {
        // call OAppSender::_lzSend
    }
}
