// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/DeployTarget.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);
        (TransparentUpgradeableProxy targetCore, MellowOFT mellowOFT) = DeployTarget.deploy(
            TargetCore(0x1bfbF13aF629eB2bC829393D10f5f4a2B84EFF70),
            Constants.SOLV_MAINNET_VAULT_PROXY_ADMIN(),
            deployer,
            bytes32(uint256(0x2)),
            "SOLV Vault OFT",
            "SOLV OFT"
        );

        vm.stopBroadcast();

        console2.log("TargetCore SOLV %s;", address(targetCore));
        console2.log("MellowOFT SOLV %s.", address(mellowOFT));

        //revert("ok");
    }
}
