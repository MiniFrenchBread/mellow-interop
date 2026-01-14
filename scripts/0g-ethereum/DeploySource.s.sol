// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/DeploySource.sol";
import "./Params.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);
        (TransparentUpgradeableProxy sourceCore, MellowOFTAdapter mellowOFTAdapter) =
            DeploySource.deploy(Params.sourceCoreImpl, Params.asset, Params.proxyAdmin, deployer, bytes32(uint256(0x0)));
        vm.stopBroadcast();

        console2.log("SourceCore impl %s;", address(sourceCoreSingleton));
        console2.log("SourceCore WOG %s;", address(sourceCore));
        console2.log("MellowOFTAdapter WOG %s.", address(mellowOFTAdapter));

        // revert("ok");
    }
}
