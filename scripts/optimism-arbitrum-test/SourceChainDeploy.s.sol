// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/DeploySource.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("TEST_DEPLOYER")));
        address deployer = vm.addr(deployerPk);
        bytes32 salt = bytes32(uint256(5));

        vm.startBroadcast(deployerPk);
        (SourceCore sourceCoreSingleton, TransparentUpgradeableProxy sourceCore, MellowOFTAdapter mellowOFTAdapter) =
            DeploySource.deploy(Constants.wsteth(), deployer, deployer, salt);
        vm.stopBroadcast();

        console2.log("SourceCore singleton %s;", address(sourceCoreSingleton));
        console2.log("SourceCore %s;", address(sourceCore));
        console2.log("MellowOFTAdapter %s.", address(mellowOFTAdapter));
    }
}
