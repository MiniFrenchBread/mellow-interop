// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/DeploySource.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("TEST_DEPLOYER")));
        address deployer = vm.addr(deployerPk);
        bytes32 salt = bytes32(uint256(1));

        vm.startBroadcast(deployerPk);
        (SourceCore sourceCoreSingleton, TransparentUpgradeableProxy sourceCore, MellowOFTAdapter mellowOFTAdapter) =
            DeploySource.deploy(Constants.wsteth(), deployer, deployer, salt);
        vm.stopBroadcast();

        console2.log("SourceCore singleton %s;", address(sourceCoreSingleton));
        console2.log("SourceCore %s;", address(sourceCore));
        console2.log("MellowOFTAdapter %s.", address(mellowOFTAdapter));
    }
}

/*
    SourceCore singleton 0xcB536c7E2368970EEc0CBe46eBc5D79C7b72f4BD;
    SourceCore 0x0cFC89E03c52F1F091544De5848EBaFf21148DCc;
    MellowOFTAdapter 0xEF50Ef9Ea5B7Ae605DF63245cebCd01a94C81f90.
*/
