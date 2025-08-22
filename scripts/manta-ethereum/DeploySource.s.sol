// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/DeploySource.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);
        (SourceCore sourceCoreImplementation, TransparentUpgradeableProxy sourceCore, MellowOFTAdapter mellowOFTAdapter)
        = DeploySource.deploy(Constants.manta(), Constants.MANTA_SOURCE_VAULT_PROXY_ADMIN(), deployer, bytes32(0));
        vm.stopBroadcast();

        console2.log("SourceCore implementation %s", address(sourceCoreImplementation));
        console2.log("SourceCore MANTA          %s", address(sourceCore));
        console2.log("MellowOFTAdapter MANTA    %s", address(mellowOFTAdapter));
        console2.log("Vault Proxy admin MANTA   %s", Constants.MANTA_SOURCE_VAULT_PROXY_ADMIN());

        revert("ok");
    }
}
