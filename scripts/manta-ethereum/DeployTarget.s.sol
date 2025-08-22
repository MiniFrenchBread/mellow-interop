// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/DeployTarget.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);

        (TargetCore targetCoreSingleton, TransparentUpgradeableProxy targetCore, MellowOFT mellowOFT) = DeployTarget
            .deploy(
            Constants.MANTA_TARGET_VAULT_PROXY_ADMIN(),
            deployer,
            bytes32(0),
            "Manta Restaking Vault OFT",
            "mstManta OFT"
        );

        vm.stopBroadcast();

        console2.log("TargetCore Implementation %s", address(targetCoreSingleton));
        console2.log("TargetCore MANTA          %s", address(targetCore));
        console2.log("MellowOFT MANTA           %s", address(mellowOFT));
        console2.log("Vault Proxy admin MANTA   %s", Constants.MANTA_TARGET_VAULT_PROXY_ADMIN());

        revert("ok");
    }
}
