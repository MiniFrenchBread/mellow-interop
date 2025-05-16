// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import {Collector} from "./Collector.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("TEST_DEPLOYER")));

        vm.startBroadcast(deployerPk);

        Collector collector = new Collector();
        console2.log("Collector deployed to:", address(collector));

        vm.stopBroadcast();
        // revert("ok");
    }
}
