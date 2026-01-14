// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/DeployTarget.sol";
import "./Params.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);
        (TransparentUpgradeableProxy targetCore, MellowOFT mellowOFT) = DeployTarget.deploy(
            Params.targetCoreImpl, Params.proxyAdmin, deployer, bytes32(0), Params.oftName, Params.oftSymbol
        );

        vm.stopBroadcast();

        console2.log("TargetCore OG %s;", address(targetCore));
        console2.log("MellowOFT OG %s.", address(mellowOFT));

        //revert("ok");
    }
}
