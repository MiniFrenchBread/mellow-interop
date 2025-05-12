// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/DeploySource.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("DEPLOYER_PK")));
        address deployer = vm.addr(deployerPk);
        vm.startBroadcast(deployerPk);
        (
            SourceCore sourceCoreSingleton,
            TransparentUpgradeableProxy sourceCoreWSTETH,
            MellowOFTAdapter mellowOFTAdapterWSTETH
        ) = DeploySource.deploy(Constants.wsteth(), Constants.LISK_PROXY_ADMIN(), deployer, bytes32(uint256(1)));

        (TransparentUpgradeableProxy sourceCoreMBTC, MellowOFTAdapter mellowOFTAdapterMBTC) = DeploySource.deploy(
            sourceCoreSingleton, Constants.mbtc(), Constants.LISK_PROXY_ADMIN(), deployer, bytes32(uint256(2))
        );

        (TransparentUpgradeableProxy sourceCoreLSK, MellowOFTAdapter mellowOFTAdapterLSK) = DeploySource.deploy(
            sourceCoreSingleton, Constants.lsk(), Constants.LISK_PROXY_ADMIN(), deployer, bytes32(uint256(3))
        );
        vm.stopBroadcast();

        console2.log("SourceCore singleton %s;", address(sourceCoreSingleton));
        console2.log("SourceCore WSTETH %s;", address(sourceCoreWSTETH));
        console2.log("MellowOFTAdapter WSTETH %s.", address(mellowOFTAdapterWSTETH));

        console2.log("SourceCore MBTC %s;", address(sourceCoreMBTC));
        console2.log("MellowOFTAdapter MBTC %s.", address(mellowOFTAdapterMBTC));

        console2.log("SourceCore LSK %s;", address(sourceCoreLSK));
        console2.log("MellowOFTAdapter LSK %s.", address(mellowOFTAdapterLSK));

        // revert("ok");
    }
}

/*
    SourceCore singleton 0x39c62c6308BeD7B0832CAfc2BeA0C0eDC7f2060c;
    SourceCore WSTETH 0x2dE9fa30638960580dbFFece296333e5ca8Cb255;
    MellowOFTAdapter WSTETH 0xA1e96AE1Af42EBF3E3D8738c576d2fD57c02e05b.
    SourceCore MBTC 0xAe2b785bbBE30755585df96F0d0FdE2A9e28c3fC;
    MellowOFTAdapter MBTC 0x5dc6B9Fb10F11a134914c025990A54C3CFEb5154.
    SourceCore LSK 0x49203fC2cD1924D75BA15Da77C337f8eF332E318;
    MellowOFTAdapter LSK 0x60Ea399d5C03C2aE799093F8fd3F44480BEB1e25.
*/
