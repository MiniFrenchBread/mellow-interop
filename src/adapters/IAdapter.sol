// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

interface IAdapter {
    function send(bytes32 chainId, bytes32 receiver, uint256 value, bytes calldata data) external payable;
}
