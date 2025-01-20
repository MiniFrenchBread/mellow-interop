// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract MockVault is ERC4626 {
    constructor(string memory name_, string memory symbol_, address asset_)
        ERC20(name_, symbol_)
        ERC4626(IERC20(asset_))
    {}
}
