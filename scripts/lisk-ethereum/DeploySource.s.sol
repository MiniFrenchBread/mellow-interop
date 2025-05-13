// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/DeploySource.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("DEPLOYER_PK")));
        address deployer = vm.addr(deployerPk);

        SourceCore sourceCoreSingleton = SourceCore(0x39c62c6308BeD7B0832CAfc2BeA0C0eDC7f2060c);
        vm.startBroadcast(deployerPk);
        (TransparentUpgradeableProxy sourceCoreWSTETH, MellowOFTAdapter mellowOFTAdapterWSTETH) = DeploySource.deploy(
            sourceCoreSingleton, Constants.wsteth(), Constants.LISK_PROXY_ADMIN(), deployer, bytes32(uint256(4))
        );

        (TransparentUpgradeableProxy sourceCoreMBTC, MellowOFTAdapter mellowOFTAdapterMBTC) = DeploySource.deploy(
            sourceCoreSingleton, Constants.mbtc(), Constants.LISK_PROXY_ADMIN(), deployer, bytes32(uint256(5))
        );

        (TransparentUpgradeableProxy sourceCoreLSK, MellowOFTAdapter mellowOFTAdapterLSK) = DeploySource.deploy(
            sourceCoreSingleton, Constants.lsk(), Constants.LISK_PROXY_ADMIN(), deployer, bytes32(uint256(6))
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
  SourceCore WSTETH 0x1b10E2270780858923cdBbC9B5423e29fffD1A44;
  MellowOFTAdapter WSTETH 0x1ddBeBd9aaBe4B9660d9Bba5de2949DA1Ae4D229.
  SourceCore MBTC 0xa67E8B2E43B70D98E1896D3f9d563f3ABdB8Adcd;
  MellowOFTAdapter MBTC 0x34B22c672b3dA8396f4A66324703590a945129De.
  SourceCore LSK 0x8cf94b5A37b1835D634b7a3e6b1EE02Ce7F0CD30;
  MellowOFTAdapter LSK 0xcDf0b12Ef7716f3848F98D77dD842bFBDCF6b857.
*/
