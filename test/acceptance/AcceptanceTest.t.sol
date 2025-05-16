// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../Constants.sol";
import "./AcceptanceRunner.sol";

contract AcceptanceTest is AcceptanceRunner, Test {
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

    function testLiskWstETHDeployment() external {
        Deployment memory $ = Deployment({
            asset: Constants.wsteth(Constants.LISK_CHAINID),
            limit: 1000 ether,
            sourceChainId: Constants.LISK_CHAINID,
            oftAdapter: 0x1ddBeBd9aaBe4B9660d9Bba5de2949DA1Ae4D229,
            sourceCore: 0x1b10E2270780858923cdBbC9B5423e29fffD1A44,
            oracle: 0x83D65E663B48bd19488a3AB9996175805760dcbF,
            withdrawalQueue: 0x5E3584d67b86f0C77FB43073A1238a943CA26188,
            targetChainId: Constants.ETHEREUM_CHAINID,
            targetCore: 0x7E0E4B05898181a597673cD5a8FeF2B9E36bEC97,
            oft: 0x552f1C7E18Bc2013c7FEec7B8F2cB18c8461469e,
            vault: 0x628C053E196FcCB986Cf2105136Ef11e4CE5d4ED,
            claimer: 0x25024a3017B8da7161d8c5DCcF768F8678fB5802,
            vaultAdmin: Constants.LISK_ADMIN(),
            vaultProxyAdmin: Constants.LISK_PROXY_ADMIN(),
            curatorAdmin: Constants.LISK_CURATOR_ADMIN(),
            curatorOperator: Constants.LISK_CURATOR_OPERATOR(),
            oracleUpdater: Constants.LISK_ORACLE_UPDATER()
        });

        if (block.chainid == $.sourceChainId) {
            runSourceAcceptance($);
        } else if (block.chainid == $.targetChainId) {
            runTargetAcceptance($);
        } else {
            console2.log("Unsupported Chain ID:", block.chainid);
        }
    }

    function testLiskMBTCDeployment() external {
        Deployment memory $ = Deployment({
            asset: Constants.mbtc(Constants.LISK_CHAINID),
            limit: 100 ether,
            sourceChainId: Constants.LISK_CHAINID,
            oftAdapter: 0x34B22c672b3dA8396f4A66324703590a945129De,
            sourceCore: 0xa67E8B2E43B70D98E1896D3f9d563f3ABdB8Adcd,
            oracle: 0xfEf5CE93C866A64B65A553eFE973dd228f44afdC,
            withdrawalQueue: 0x8294c6B7ed0dEf4Bcf0c1a34c9A09Fe0880D8A13,
            targetChainId: Constants.ETHEREUM_CHAINID,
            targetCore: 0xB2657a1EB016692509F321A4365551e2EC1173C2,
            oft: 0x57a013aC2A8790D3133f151F22a16fF2aC68627f,
            vault: 0x354822625Acd925d02ac13f1C96dba2aA5EE7cC6,
            claimer: 0x25024a3017B8da7161d8c5DCcF768F8678fB5802,
            vaultAdmin: Constants.LISK_ADMIN(),
            vaultProxyAdmin: Constants.LISK_PROXY_ADMIN(),
            curatorAdmin: Constants.LISK_CURATOR_ADMIN(),
            curatorOperator: Constants.LISK_CURATOR_OPERATOR(),
            oracleUpdater: Constants.LISK_ORACLE_UPDATER()
        });

        if (block.chainid == $.sourceChainId) {
            runSourceAcceptance($);
        } else if (block.chainid == $.targetChainId) {
            runTargetAcceptance($);
        } else {
            console2.log("Unsupported Chain ID:", block.chainid);
        }
    }

    function testLiskLSKDeployment() external {
        Deployment memory $ = Deployment({
            asset: Constants.lsk(Constants.LISK_CHAINID),
            limit: 10e6 ether,
            sourceChainId: Constants.LISK_CHAINID,
            oftAdapter: 0xcDf0b12Ef7716f3848F98D77dD842bFBDCF6b857,
            sourceCore: 0x8cf94b5A37b1835D634b7a3e6b1EE02Ce7F0CD30,
            oracle: 0xFe5EA142755e82a5364cBC1F7cF4b10c7D929EC2,
            withdrawalQueue: 0x025e059BCea0eAdBb58b16db7D2e5748736F6511,
            targetChainId: Constants.ETHEREUM_CHAINID,
            targetCore: 0xcc1D3926E079c826Cd807FdF825a6777846bb5C1,
            oft: 0x1e6b0fF883378Bf8ECb6b8D3A292933f6859384f,
            vault: 0xB1653ee92b724a033338CC17896E06275A4E9335,
            claimer: 0x25024a3017B8da7161d8c5DCcF768F8678fB5802,
            vaultAdmin: Constants.LISK_ADMIN(),
            vaultProxyAdmin: Constants.LISK_PROXY_ADMIN(),
            curatorAdmin: Constants.LISK_CURATOR_ADMIN(),
            curatorOperator: Constants.LISK_CURATOR_OPERATOR(),
            oracleUpdater: Constants.LISK_ORACLE_UPDATER()
        });

        if (block.chainid == $.sourceChainId) {
            runSourceAcceptance($);
        } else if (block.chainid == $.targetChainId) {
            runTargetAcceptance($);
        } else {
            console2.log("Unsupported Chain ID:", block.chainid);
        }
    }
}
