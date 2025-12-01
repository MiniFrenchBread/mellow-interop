// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../Constants.sol";
import "forge-std/Script.sol";

import "../../src/helpers/Collector.sol";
import "../../src/helpers/SourceHelper.sol";

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256 _wad) external;
}

contract Deploy is Script {
    SourceCore public immutable sourceCore = SourceCore(0xc07510228bB180985C6009C24ED5D05fdfC82F84);
    MellowOFTAdapter public immutable sourceMellowOFTAdapter =
        MellowOFTAdapter(0xA83067d29b9671eECbDb9A3290ded33c63659b99);
    SourceHelper public immutable helper =
        SourceHelper(0x09c03ea586A6b4058bd39C78Ef91e492e3b2E14A);
    Collector public immutable collector =
        Collector(0x3E2B0eA1EE00fB826Cbb7609501310A9D083Dc2f);

    address public constant assets = 0x1Cd0690fF9a693f5EF2dD976660a8dAFc81A109c; // WOG

    // Collector    0x3E2B0eA1EE00fB826Cbb7609501310A9D083Dc2f
    // SourceHelper 0x09c03ea586A6b4058bd39C78Ef91e492e3b2E14A
    function run() external {
        //makeDeposit();
        pushToTarget();
        //revert("ok");
    }

    function deployHelper() internal {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        address deployer = vm.addr(deployerPk);
        vm.startBroadcast(deployerPk);

        Collector collector = new Collector();
        SourceHelper sourceHelper = new SourceHelper();

        vm.stopBroadcast();
        console2.log("Collector    %s", address(collector));
        console2.log("SourceHelper %s", address(sourceHelper));
    }

    function makeDeposit() internal {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        uint256 amount = 0.001 ether;
        address asset = sourceCore.asset();

        vm.startBroadcast(deployerPk);

        IWETH(asset).deposit{value: amount}();
        IERC20(asset).approve(address(sourceCore), amount);
        sourceCore.deposit(amount, deployer);

        vm.stopBroadcast();
    }

    function pushToTarget() internal {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER"))); 
        uint256 adminPk = uint256(bytes32(vm.envBytes("ADMIN_OG_TEST")));
        address deployer = vm.addr(deployerPk);
        address admin = vm.addr(adminPk);
        uint256 fee = helper.quotePushToTarget(sourceCore); 

        if (!sourceCore.hasRole(sourceCore.PUSH_ROLE(), deployer)) {
            vm.startBroadcast(deployerPk);
            admin.call{value: 0.01 ether} ("");
            vm.stopBroadcast();

            vm.startBroadcast(adminPk);
            sourceCore.grantRole(sourceCore.PUSH_ROLE(), deployer);
            vm.stopBroadcast();
        }

        vm.startBroadcast(deployerPk);
        sourceCore.pushToTarget{value: fee}();
        vm.stopBroadcast();
    }
}
