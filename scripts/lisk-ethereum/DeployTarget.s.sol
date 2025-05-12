// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/DeployTarget.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("DEPLOYER_PK")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);
        (TargetCore targetCoreSigleton, TransparentUpgradeableProxy targetCoreWSTETH, MellowOFT mellowOFTWSTETH) =
        DeployTarget.deploy(
            Constants.LISK_PROXY_ADMIN(), deployer, bytes32(uint256(1)), "Lisk wstETH Vault OFT", "lskETH-OFT"
        );
        (TransparentUpgradeableProxy targetCoreMBTC, MellowOFT mellowOFTMBTC) = DeployTarget.deploy(
            targetCoreSigleton,
            Constants.LISK_PROXY_ADMIN(),
            deployer,
            bytes32(uint256(2)),
            "Lisk rsmBTC Vault OFT",
            "rsM-BTC-OFT"
        );
        (TransparentUpgradeableProxy targetCoreLSK, MellowOFT mellowOFTLSK) = DeployTarget.deploy(
            targetCoreSigleton,
            Constants.LISK_PROXY_ADMIN(),
            deployer,
            bytes32(uint256(3)),
            "Lisk LSK Vault OFT",
            "rsLSK-OFT"
        );

        vm.stopBroadcast();

        console2.log("TargetCore singleton %s;", address(targetCoreSigleton));

        console2.log("TargetCore WSTETH %s;", address(targetCoreWSTETH));
        console2.log("MellowOFT WSTETH %s.", address(mellowOFTWSTETH));

        console2.log("TargetCore MBTC %s;", address(targetCoreMBTC));
        console2.log("MellowOFT MBTC %s.", address(mellowOFTMBTC));

        console2.log("TargetCore LSK %s;", address(targetCoreLSK));
        console2.log("MellowOFT LSK %s.", address(mellowOFTLSK));

        // revert("ok");
    }
}

/*
    TargetCore singleton 0xa21aa0efDA3a4557daAe3Eb96d78962a9db9Cf6A;
    TargetCore WSTETH 0xb58D06eCC39cD6955542861d4374845Ed2014140;
    MellowOFT WSTETH 0x7f98073e7234B7c7F9d0223168dBCd95feAfba58.
    TargetCore MBTC 0x197A5CaE846984F00Ff650b11a31907aEd7B959c;
    MellowOFT MBTC 0xdFCaB55563345Ed11616A377a6ba6189F2B57d4c.
    TargetCore LSK 0xf2BA9Dab43d5D9014eCA96f058C6dF3945b919bD;
    MellowOFT LSK 0x20347ece0df3B4B413eE656B9FfCc0562285be71.
*/
