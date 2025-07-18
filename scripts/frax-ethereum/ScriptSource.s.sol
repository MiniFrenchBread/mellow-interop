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

        SourceCore core = SourceCore(0x24dD1eaBEad7b3cB07b7d162439ec0A4EEC703DF);
        address asset = core.asset();
        uint256 amount = 0.001 ether;
        IWETH(asset).deposit{value: amount}();
        IERC20(asset).approve(address(core), type(uint256).max);
        core.deposit(amount, deployer);
        vm.stopBroadcast();
        // revert("ok");
    }
}
