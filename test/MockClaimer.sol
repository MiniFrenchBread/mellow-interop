// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MockClaimer {
    function claim(address asset, uint256 amount) external returns (uint256) {
        SafeERC20.safeTransfer(IERC20(asset), msg.sender, amount);
        return amount;
    }

    function testMockClaimer() private pure {}
}
