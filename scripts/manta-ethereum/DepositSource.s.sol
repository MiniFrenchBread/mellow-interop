// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../Constants.sol";
import "forge-std/Script.sol";

interface IWETH {
    function deposit() external payable;
}

contract Deploy is Script {
    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        address deployer = vm.addr(deployerPk);
        vm.startBroadcast(deployerPk);

        SourceCore core = SourceCore(0x9cD45b6E33433ED50738F508aD378b567603f61F);
        address asset = core.asset();
        uint256 amount = IERC20(asset).balanceOf(deployer);
        IERC20(asset).approve(address(core), amount);
        core.deposit(amount, deployer);
        vm.stopBroadcast();
        revert("ok");
    }
}
