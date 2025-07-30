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
        = DeploySource.deploy(Constants.cyc(), Constants.CYCLE_MAINNET_VAULT_PROXY_ADMIN(), deployer, bytes32(0));
        vm.stopBroadcast();

        console2.log("SourceCore implementation %s;", address(sourceCoreImplementation));
        console2.log("SourceCore CYC %s;", address(sourceCore));
        console2.log("MellowOFTAdapter CYC %s.", address(mellowOFTAdapter));

        // revert("ok");
    }
}
