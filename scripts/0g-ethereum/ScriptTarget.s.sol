// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../Constants.sol";
import "forge-std/Script.sol";
import "src/helpers/TargetHelper.sol";

contract Deploy is Script {
    using OptionsBuilder for bytes;

    TargetCore public targetCore = TargetCore(address(0));

    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        vm.startBroadcast(deployerPk);

        TargetHelper targetHelper = new TargetHelper();

        vm.stopBroadcast();
        console2.log("TargetHelper %s", address(targetHelper));
        //revert("ok");
    }
}
