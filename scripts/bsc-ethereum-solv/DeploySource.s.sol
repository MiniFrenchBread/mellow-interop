// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/DeploySource.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);
        (TransparentUpgradeableProxy sourceCore, MellowOFTAdapter mellowOFTAdapter) = DeploySource.deploy(
            SourceCore(0x2F83162511A07769fd3F981D02Ae5b3138Ff72cE),
            Constants.solv(),
            Constants.SOLV_MAINNET_VAULT_PROXY_ADMIN(),
            deployer,
            bytes32(uint256(0x1))
        );
        vm.stopBroadcast();

        console2.log("SourceCore SOLV %s;", address(sourceCore));
        console2.log("MellowOFTAdapter SOLV %s.", address(mellowOFTAdapter));

        // revert("ok");
    }
}
