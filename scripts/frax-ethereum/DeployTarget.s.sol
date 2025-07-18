// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/DeployTarget.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);
        (TargetCore targetCore, TransparentUpgradeableProxy targetCore, MellowOFT mellowOFT) = DeployTarget.deploy(
            Constants.ETHEREUM_PROXY_ADMIN(), deployer, bytes32(uint256(1)), "FRAX Vault OFT", "rstFRAX-OFT"
        );

        vm.stopBroadcast();

        console2.log("TargetCore implementation %s;", address(targetCoreImplementation));
        console2.log("TargetCore FRAX %s;", address(targetCore));
        console2.log("MellowOFT FRAX %s.", address(mellowOFT));

        // revert("ok");
    }
}
