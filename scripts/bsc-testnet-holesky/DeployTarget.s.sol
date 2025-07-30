// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/DeployTarget.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);
        (TargetCore targetCoreImplementation, TransparentUpgradeableProxy targetCore, MellowOFT mellowOFT) =
        DeployTarget.deploy(
            Constants.HOLESKY_CYCLE_VAULT_PROXY_ADMIN(),
            deployer,
            bytes32(0),
            "Cycle Test Interop Vault OFT",
            "CYC-TIV-OFT"
        );

        vm.stopBroadcast();

        console2.log("TargetCore implementation %s;", address(targetCoreImplementation));
        console2.log("TargetCore CYC %s;", address(targetCore));
        console2.log("MellowOFT CYC %s.", address(mellowOFT));

        // revert("ok");
    }
}
