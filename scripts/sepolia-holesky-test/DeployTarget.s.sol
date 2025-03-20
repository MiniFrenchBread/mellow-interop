// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/DeployTarget.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("TEST_DEPLOYER")));
        address deployer = vm.addr(deployerPk);
        bytes32 salt = bytes32(uint256(1));

        vm.startBroadcast(deployerPk);
        (TargetCore targetCoreSigleton, TransparentUpgradeableProxy targetCore, MellowOFT mellowOFT) =
            DeployTarget.deploy(deployer, deployer, salt, "Mellow Test Vault", "MTV");

        vm.stopBroadcast();

        console2.log("TargetCore singleton %s;", address(targetCoreSigleton));
        console2.log("TargetCore %s;", address(targetCore));
        console2.log("MellowOFT %s.", address(mellowOFT));
    }
}

/*
    TargetCore singleton 0x6f09a5a47E10a34460325350828151B397641efe;
    TargetCore 0x4afdf122Cc10AA017e65247DB7446a61c949628D;
    MellowOFT 0x6F678eb24036C5355600cf66ce316Cfb4BBD8B25.
*/
