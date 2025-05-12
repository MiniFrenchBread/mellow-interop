// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../Constants.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    using OptionsBuilder for bytes;

    TargetCore public targetCore = TargetCore(0x4afdf122Cc10AA017e65247DB7446a61c949628D);

    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("TEST_DEPLOYER")));
        vm.startBroadcast(deployerPk);
        targetCore.deposit(targetCore.oft().balanceOf(address(targetCore)));
        targetCore.redeem(targetCore.vault().balanceOf(address(targetCore)));
        targetCore.pushToSource{value: 0.001 ether}(targetCore.oft().balanceOf(address(targetCore)));
        vm.stopBroadcast();
    }
}
