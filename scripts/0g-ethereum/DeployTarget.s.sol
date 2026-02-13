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
            TargetCore(Params.targetCoreImpl), Params.proxyAdmin, deployer, bytes32(uint256(0x3)), Params.oftName, Params.oftSymbol
        );

        vm.stopBroadcast();

        console2.log("TargetCore impl %s", Params.targetCoreImpl);
        console2.log("TargetCore OG %s", address(targetCore));
        console2.log("MellowOFT OG %s/%s %s", Params.oftName, Params.oftSymbol, address(mellowOFT));

        //revert("ok");
    }
}
