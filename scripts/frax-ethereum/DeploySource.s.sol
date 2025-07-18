// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../../src/helpers/Collector.sol";
import "../common/DeploySource.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);
        (SourceCore sourceCoreSingleton, TransparentUpgradeableProxy sourceCore, MellowOFTAdapter mellowOFTAdapter) =
            DeploySource.deploy(Constants.frax(), Constants.FRAX_PROXY_ADMIN(), deployer, bytes32(0));
        vm.stopBroadcast();

        console2.log("SourceCore singleton %s;", address(sourceCoreSingleton));
        console2.log("SourceCore FRAX %s;", address(sourceCore));
        console2.log("MellowOFTAdapter FRAX %s.", address(mellowOFTAdapter));

        // revert("ok");
    }
}
