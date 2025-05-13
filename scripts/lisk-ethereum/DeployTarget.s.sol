// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/DeployTarget.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("DEPLOYER_PK")));
        address deployer = vm.addr(deployerPk);

        TargetCore targetCoreSigleton = TargetCore(0xa21aa0efDA3a4557daAe3Eb96d78962a9db9Cf6A);

        vm.startBroadcast(deployerPk);
        (TransparentUpgradeableProxy targetCoreWSTETH, MellowOFT mellowOFTWSTETH) = DeployTarget.deploy(
            targetCoreSigleton,
            Constants.LISK_PROXY_ADMIN(),
            deployer,
            bytes32(uint256(4)),
            "Lisk wstETH Vault OFT",
            "lskETH-OFT"
        );
        (TransparentUpgradeableProxy targetCoreMBTC, MellowOFT mellowOFTMBTC) = DeployTarget.deploy(
            targetCoreSigleton,
            Constants.LISK_PROXY_ADMIN(),
            deployer,
            bytes32(uint256(5)),
            "Lisk rsmBTC Vault OFT",
            "rsM-BTC-OFT"
        );
        (TransparentUpgradeableProxy targetCoreLSK, MellowOFT mellowOFTLSK) = DeployTarget.deploy(
            targetCoreSigleton,
            Constants.LISK_PROXY_ADMIN(),
            deployer,
            bytes32(uint256(6)),
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
  TargetCore WSTETH 0x7E0E4B05898181a597673cD5a8FeF2B9E36bEC97;
  MellowOFT WSTETH 0x552f1C7E18Bc2013c7FEec7B8F2cB18c8461469e.
  TargetCore MBTC 0xB2657a1EB016692509F321A4365551e2EC1173C2;
  MellowOFT MBTC 0x57a013aC2A8790D3133f151F22a16fF2aC68627f.
  TargetCore LSK 0xcc1D3926E079c826Cd807FdF825a6777846bb5C1;
  MellowOFT LSK 0x1e6b0fF883378Bf8ECb6b8D3A292933f6859384f.
*/
