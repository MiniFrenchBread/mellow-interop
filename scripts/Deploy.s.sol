// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "forge-std/Script.sol";

import "./SourceDeployScript.sol";

contract Deploy is Script {
    address public wsteth = 0x8d09a4502Cc8Cf1547aD300E066060D043f6982D;
    address public lzEndpoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;

    function run() external {
        // uint256 deployerPk = uint256(bytes32(vm.envBytes("HOLESKY_DEPLOYER")));
        // address deployer = vm.addr(deployerPk);
        // vm.startBroadcast(deployerPk);
        // SourceDeployScript sourceDeployScript = new SourceDeployScript();
        // sourceDeployScript.deploy(wsteth, lzEndpoint, deployer);
        // vm.stopBroadcast();
        // revert("ok");
    }
}
