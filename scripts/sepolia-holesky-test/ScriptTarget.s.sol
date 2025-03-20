// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../Constants.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    using OptionsBuilder for bytes;

    // Test deployment
    address public immutable proxyAdmin = 0x5C0F3DE4ba6AD53bb8E27f965170A52671e525Bf;
    address public immutable admin = 0x5C0F3DE4ba6AD53bb8E27f965170A52671e525Bf;
    address public immutable operator = 0x5C0F3DE4ba6AD53bb8E27f965170A52671e525Bf;

    TargetCore public targetCore = TargetCore(0xeea0Ed9d5A71569fDA65b66C5983011e67C30F8f);

    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("TEST_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);
        targetCore.deposit(targetCore.oft().balanceOf(address(targetCore)));
        targetCore.redeem(targetCore.vault().balanceOf(address(targetCore)));
        targetCore.pushToSource{value: 0.0001 ether}(targetCore.oft().balanceOf(address(targetCore)));
        vm.stopBroadcast();

        // revert("OK");
    }
}
