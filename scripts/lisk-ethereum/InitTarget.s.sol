// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/InitTarget.sol";

import {IMultiVault, MultiVault} from "@mellow-finance/simple-lrt/vaults/MultiVault.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    /*
        SourceCore WSTETH 0x1b10E2270780858923cdBbC9B5423e29fffD1A44;
        MellowOFTAdapter WSTETH 0x1ddBeBd9aaBe4B9660d9Bba5de2949DA1Ae4D229;
        TargetCore WSTETH 0x7E0E4B05898181a597673cD5a8FeF2B9E36bEC97;
        MellowOFT WSTETH 0x552f1C7E18Bc2013c7FEec7B8F2cB18c8461469e;
        vault: 0x628C053E196FcCB986Cf2105136Ef11e4CE5d4ED.

        SourceCore MBTC 0xa67E8B2E43B70D98E1896D3f9d563f3ABdB8Adcd;
        MellowOFTAdapter MBTC 0x34B22c672b3dA8396f4A66324703590a945129De;
        TargetCore MBTC 0xB2657a1EB016692509F321A4365551e2EC1173C2;
        MellowOFT MBTC 0x57a013aC2A8790D3133f151F22a16fF2aC68627f;
        vault: 0x354822625Acd925d02ac13f1C96dba2aA5EE7cC6.

        SourceCore LSK 0x8cf94b5A37b1835D634b7a3e6b1EE02Ce7F0CD30;
        MellowOFTAdapter LSK 0xcDf0b12Ef7716f3848F98D77dD842bFBDCF6b857;
        TargetCore LSK 0xcc1D3926E079c826Cd807FdF825a6777846bb5C1;
        MellowOFT LSK 0x1e6b0fF883378Bf8ECb6b8D3A292933f6859384f;
        vault: 0xB1653ee92b724a033338CC17896E06275A4E9335.
    */

    address claimer = 0x25024a3017B8da7161d8c5DCcF768F8678fB5802;

    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("DEPLOYER_PK")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);
        uint32 sourceEid = Constants.endpointId(Constants.LISK_CHAINID);
        {
            /*
                SourceCore WSTETH 0x1b10E2270780858923cdBbC9B5423e29fffD1A44;
                MellowOFTAdapter WSTETH 0x1ddBeBd9aaBe4B9660d9Bba5de2949DA1Ae4D229;
                TargetCore WSTETH 0x7E0E4B05898181a597673cD5a8FeF2B9E36bEC97;
                MellowOFT WSTETH 0x552f1C7E18Bc2013c7FEec7B8F2cB18c8461469e;
                vault: 0x628C053E196FcCB986Cf2105136Ef11e4CE5d4ED.
            */
            SourceCore sourceCore = SourceCore(0x1b10E2270780858923cdBbC9B5423e29fffD1A44);
            TargetCore targetCore = TargetCore(0x7E0E4B05898181a597673cD5a8FeF2B9E36bEC97);
            MellowOFTAdapter mellowOFTAdapter = MellowOFTAdapter(0x1ddBeBd9aaBe4B9660d9Bba5de2949DA1Ae4D229);
            MellowOFT mellowOFT = MellowOFT(0x552f1C7E18Bc2013c7FEec7B8F2cB18c8461469e);
            address vault = 0x628C053E196FcCB986Cf2105136Ef11e4CE5d4ED;
            InitTarget.init(
                InitTarget.InitParams({
                    targetCore: targetCore,
                    sourceEid: sourceEid,
                    sourceCoreAddress: address(sourceCore),
                    mellowOFT: mellowOFT,
                    mellowOFTAdapter: address(mellowOFTAdapter),
                    deployer: deployer,
                    vaultAdmin: Constants.LISK_ADMIN(),
                    vaultProxyAdmin: Constants.LISK_PROXY_ADMIN(),
                    curatorAdmin: Constants.LISK_CURATOR_ADMIN(),
                    curatorOperator: Constants.LISK_CURATOR_OPERATOR(),
                    vault: address(vault),
                    claimer: claimer
                })
            );
        }

        {
            /*
                SourceCore MBTC 0xa67E8B2E43B70D98E1896D3f9d563f3ABdB8Adcd;
                MellowOFTAdapter MBTC 0x34B22c672b3dA8396f4A66324703590a945129De;
                TargetCore MBTC 0xB2657a1EB016692509F321A4365551e2EC1173C2;
                MellowOFT MBTC 0x57a013aC2A8790D3133f151F22a16fF2aC68627f;
                vault: 0x354822625Acd925d02ac13f1C96dba2aA5EE7cC6.
            */
            SourceCore sourceCore = SourceCore(0xa67E8B2E43B70D98E1896D3f9d563f3ABdB8Adcd);
            TargetCore targetCore = TargetCore(0xB2657a1EB016692509F321A4365551e2EC1173C2);
            MellowOFTAdapter mellowOFTAdapter = MellowOFTAdapter(0x34B22c672b3dA8396f4A66324703590a945129De);
            MellowOFT mellowOFT = MellowOFT(0x57a013aC2A8790D3133f151F22a16fF2aC68627f);
            address vault = 0x354822625Acd925d02ac13f1C96dba2aA5EE7cC6;
            InitTarget.init(
                InitTarget.InitParams({
                    targetCore: targetCore,
                    sourceEid: sourceEid,
                    sourceCoreAddress: address(sourceCore),
                    mellowOFT: mellowOFT,
                    mellowOFTAdapter: address(mellowOFTAdapter),
                    deployer: deployer,
                    vaultAdmin: Constants.LISK_ADMIN(),
                    vaultProxyAdmin: Constants.LISK_PROXY_ADMIN(),
                    curatorAdmin: Constants.LISK_CURATOR_ADMIN(),
                    curatorOperator: Constants.LISK_CURATOR_OPERATOR(),
                    vault: address(vault),
                    claimer: claimer
                })
            );
        }

        {
            /*
                SourceCore LSK 0x8cf94b5A37b1835D634b7a3e6b1EE02Ce7F0CD30;
                MellowOFTAdapter LSK 0xcDf0b12Ef7716f3848F98D77dD842bFBDCF6b857;
                TargetCore LSK 0xcc1D3926E079c826Cd807FdF825a6777846bb5C1;
                MellowOFT LSK 0x1e6b0fF883378Bf8ECb6b8D3A292933f6859384f;
                vault: 0xB1653ee92b724a033338CC17896E06275A4E9335.
            */
            SourceCore sourceCore = SourceCore(0x8cf94b5A37b1835D634b7a3e6b1EE02Ce7F0CD30);
            TargetCore targetCore = TargetCore(0xcc1D3926E079c826Cd807FdF825a6777846bb5C1);
            MellowOFTAdapter mellowOFTAdapter = MellowOFTAdapter(0xcDf0b12Ef7716f3848F98D77dD842bFBDCF6b857);
            MellowOFT mellowOFT = MellowOFT(0x1e6b0fF883378Bf8ECb6b8D3A292933f6859384f);
            address vault = 0xB1653ee92b724a033338CC17896E06275A4E9335;
            InitTarget.init(
                InitTarget.InitParams({
                    targetCore: targetCore,
                    sourceEid: sourceEid,
                    sourceCoreAddress: address(sourceCore),
                    mellowOFT: mellowOFT,
                    mellowOFTAdapter: address(mellowOFTAdapter),
                    deployer: deployer,
                    vaultAdmin: Constants.LISK_ADMIN(),
                    vaultProxyAdmin: Constants.LISK_PROXY_ADMIN(),
                    curatorAdmin: Constants.LISK_CURATOR_ADMIN(),
                    curatorOperator: Constants.LISK_CURATOR_OPERATOR(),
                    vault: address(vault),
                    claimer: claimer
                })
            );
        }

        vm.stopBroadcast();
        // revert("ok");
    }
}
