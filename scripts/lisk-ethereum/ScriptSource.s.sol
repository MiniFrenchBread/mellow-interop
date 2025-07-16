// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../Constants.sol";
import "forge-std/Script.sol";

interface IUrdFactory {
    function createUrd(
        address initialOwner,
        uint256 initialTimelock,
        bytes32 initialRoot,
        bytes32 initialIpfsHash,
        bytes32 salt
    ) external returns (address urd);
}

contract Deploy is Script {
    address public constant URD_FARM_FACTORY = 0xC3da6acf214e322Cc0E07D1582c9a546fB4338da;
    address public constant RE7_FARM_ADMIN = 0xa62243c7a36e74d8280781242a3B0e019ce74E64;

    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("TEST_DEPLOYER")));
        // address deployer = vm.addr(deployerPk);
        vm.startBroadcast(deployerPk);
        address[3] memory cores = [
            0x1b10E2270780858923cdBbC9B5423e29fffD1A44,
            0xa67E8B2E43B70D98E1896D3f9d563f3ABdB8Adcd,
            0x8cf94b5A37b1835D634b7a3e6b1EE02Ce7F0CD30
        ];
        for (uint256 i = 0; i < cores.length; i++) {
            address core = cores[i];
            bytes32 salt = keccak256(abi.encode(RE7_FARM_ADMIN, core));
            address farm = IUrdFactory(URD_FARM_FACTORY).createUrd(RE7_FARM_ADMIN, 0, bytes32(0), bytes32(0), salt);
            console2.log(
                "URD farm: SourceCore: %s; URD farm: %s; URD farm admin: %s",
                SourceCore(core).symbol(),
                farm,
                RE7_FARM_ADMIN
            );
        }
        vm.stopBroadcast();
        // revert("ok");
    }
}
