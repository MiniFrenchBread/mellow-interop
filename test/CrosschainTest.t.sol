// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "./Imports.sol";

contract CrosschainTest is TestHelperOz5 {
    // using OptionsBuilder for bytes;

    function test() public {
        MellowOFTAdapter adapter = new MellowOFTAdapter(
            address(this),
            0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0,
            0x1a44076050125825900e736c501f859c50fE728c,
            address(this)
        );
    }
}

import "../src/oft/MellowOFTAdapter.sol";
