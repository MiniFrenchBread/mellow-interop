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

    TargetCore public targetCoreSigleton;
    TransparentUpgradeableProxy public targetCore;
    MellowOFT public mellowOFT;

    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("TEST_DEPLOYER")));
        address deployer = vm.addr(deployerPk);
        bytes32 salt = bytes32(uint256(12345));

        vm.startBroadcast(deployerPk);

        targetCoreSigleton = new TargetCore();
        targetCore = new TransparentUpgradeableProxy{salt: salt}(address(targetCoreSigleton), proxyAdmin, "");
        mellowOFT = new MellowOFT{salt: salt}("MellowOFT", "MOFT", Constants.endpointV2(), deployer);

        vm.stopBroadcast();

        console2.log("TargetCore singleton %s;", address(targetCoreSigleton));
        console2.log("TargetCore %s;", address(targetCore));
        console2.log("MellowOFT %s.", address(mellowOFT));

        // revert("OK");
    }
}
