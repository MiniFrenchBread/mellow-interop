// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../Constants.sol";
import "forge-std/Script.sol";

import "../../src/helpers/Collector.sol";
import "../../src/helpers/SourceHelper.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        address deployer = vm.addr(deployerPk);
        vm.startBroadcast(deployerPk);

        Collector collector = new Collector();
        SourceHelper sourceHelper = new SourceHelper();

        vm.stopBroadcast();
        revert("ok");
    }
}
