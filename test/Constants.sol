// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

library Constants {
    function WSTETH() external view returns (address) {
        uint256 id = block.chainid;
        if (id == 1) {
            return 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
        } else if (id == 17000) {
            return 0x8d09a4502Cc8Cf1547aD300E066060D043f6982D;
        }
        revert("Unsupported chain");
    }

    function LZ_ENDPOINT() external view returns (address) {
        uint256 id = block.chainid;
        if (id == 1) {
            return 0x1a44076050125825900e736c501f859c50fE728c;
        } else if (id == 17000) {
            return 0x6EDCE65403992e310A62460808c4b910D972f10f;
        }
        revert("Unsupported chain");
    }

    function testConstants() private pure {}
}
