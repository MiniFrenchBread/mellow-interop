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

        // Collector collector = new Collector();
        // console2.log("Collector deployed to:", address(collector));

        if (block.chainid == 1) {
            TargetHelper targetHelper = new TargetHelper();
            // targetHelper.getNounces(TargetCore(0x7E0E4B05898181a597673cD5a8FeF2B9E36bEC97));
            // targetHelper.getAmounts(TargetCore(0x7E0E4B05898181a597673cD5a8FeF2B9E36bEC97), 1 ether);
            // targetHelper.getNounces(TargetCore(0xB2657a1EB016692509F321A4365551e2EC1173C2));
            // targetHelper.getAmounts(TargetCore(0xB2657a1EB016692509F321A4365551e2EC1173C2), 1 ether);
            // targetHelper.getNounces(TargetCore(0xcc1D3926E079c826Cd807FdF825a6777846bb5C1));
            // targetHelper.getAmounts(TargetCore(0xcc1D3926E079c826Cd807FdF825a6777846bb5C1), 1 ether);
            console2.log("TargetHelper deployed to:", address(targetHelper));
        } else {
            SourceHelper sourceHelper = new SourceHelper();
            // sourceHelper.getNounces(SourceCore(0x1b10E2270780858923cdBbC9B5423e29fffD1A44));
            // sourceHelper.getAmounts(SourceCore(0x1b10E2270780858923cdBbC9B5423e29fffD1A44));
            // sourceHelper.getNounces(SourceCore(0xa67E8B2E43B70D98E1896D3f9d563f3ABdB8Adcd));
            // sourceHelper.getAmounts(SourceCore(0xa67E8B2E43B70D98E1896D3f9d563f3ABdB8Adcd));
            // sourceHelper.getNounces(SourceCore(0x8cf94b5A37b1835D634b7a3e6b1EE02Ce7F0CD30));
            // sourceHelper.getAmounts(SourceCore(0x8cf94b5A37b1835D634b7a3e6b1EE02Ce7F0CD30));
            console2.log("SourceHelper deployed to:", address(sourceHelper));
        }
        vm.stopBroadcast();
        // revert("ok");
    }
}
