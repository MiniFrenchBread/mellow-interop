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
}
