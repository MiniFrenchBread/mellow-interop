// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "forge-std/Script.sol";

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "../src/core/TargetCore.sol";
import "../src/oft/MellowOFT.sol";
import "../src/utils/Delegator.sol";
import "./Constants.sol";

contract Deploy is Script {
    // Test deployment
    address public immutable proxyAdmin = 0x5C0F3DE4ba6AD53bb8E27f965170A52671e525Bf;
    address public immutable admin = 0x5C0F3DE4ba6AD53bb8E27f965170A52671e525Bf;
    address public immutable operator = 0x5C0F3DE4ba6AD53bb8E27f965170A52671e525Bf;

    TargetCore public targetCore;
    MellowOFT public mellowOFT;

    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("TEST_DEPLOYER")));
        address deployer = vm.addr(deployerPk);
        bytes32 salt = keccak256(abi.encodePacked(deployer, block.chainid, 12345));

        vm.startBroadcast(deployerPk);
        sourceCoreSingleton = new SourceCore{salt: salt}();
        delegator = new Delegator{salt: salt}(coreAdmin, coreOperator, Constants.endpointV2());
        sourceCore = SourceCore(
            address(new TransparentUpgradeableProxy{salt: salt}(address(sourceCoreSingleton), proxyAdmin, ""))
        );
        mellowOFTAdapter =
            new MellowOFTAdapter{salt: salt}(Constants.wsteth(), Constants.endpointV2(), address(delegator));

        vm.stopBroadcast();

        console2.log("SourceCore singleton %s;", address(sourceCoreSingleton));
        console2.log("Delegator %s;", address(delegator));
        console2.log("SourceCore %s;", address(sourceCore));
        console2.log("MellowOFTAdapter %s.", address(mellowOFTAdapter));

        revert("OK");
    }
}
