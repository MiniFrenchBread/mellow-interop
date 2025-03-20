// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../Constants.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    SourceCore public sourceCore = SourceCore(0x0cFC89E03c52F1F091544De5848EBaFf21148DCc);

    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("TEST_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);
        IERC20 asset = IERC20(sourceCore.asset());
        Address.sendValue(payable(address(asset)), 0.04 ether);
        uint256 balance = asset.balanceOf(deployer);
        // asset.approve(address(sourceCore), type(uint256).max);
        sourceCore.deposit(balance, deployer);
        sourceCore.pushToTarget{value: 0.001 ether}();
        vm.stopBroadcast();
    }
}
