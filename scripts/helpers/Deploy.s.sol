// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import {Collector} from "../../src/helpers/Collector.sol";
import "../../src/helpers/SourceHelper.sol";
import "../../src/helpers/TargetHelper.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("TEST_DEPLOYER")));

        vm.startBroadcast(deployerPk);
        if (block.chainid == 11155111) {
            SourceHelper sourceHelper = new SourceHelper();
            console2.log("SourceHelper deployed to:", address(sourceHelper));
        } else if (block.chainid == 17000) {
            TargetHelper targetHelper = new TargetHelper();
            console2.log("TargetHelper deployed to:", address(targetHelper));
        } else {
            revert("Unsupported chain ID");
        }
        vm.stopBroadcast();
        // revert("ok");
    }
}
