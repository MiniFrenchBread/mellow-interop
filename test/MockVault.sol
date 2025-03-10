// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

contract MockVault is ERC4626Upgradeable {
    function init(string memory name_, string memory symbol_, address asset_) external initializer {
        __ERC20_init(name_, symbol_);
        __ERC4626_init(IERC20(asset_));
    }

    function testMockVault() private pure {}

    function redeem(uint256 shares, address, address) public override returns (uint256) {
        return 0;
    }

    function pull(address claimer) external {
        IERC20(asset()).transfer(address(claimer), IERC20(asset()).balanceOf(address(this)));
    }
}
