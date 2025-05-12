// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/InitSource.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    /*
        SourceCore WSTETH 0x2dE9fa30638960580dbFFece296333e5ca8Cb255;
        MellowOFTAdapter WSTETH 0xA1e96AE1Af42EBF3E3D8738c576d2fD57c02e05b;
        TargetCore WSTETH 0xb58D06eCC39cD6955542861d4374845Ed2014140;
        MellowOFT WSTETH 0x7f98073e7234B7c7F9d0223168dBCd95feAfba58;
        MultiVault WSTETH 0x176209cBD27CF9DF26d2A971E6649417Cb3F9b7F.

        SourceCore MBTC 0xAe2b785bbBE30755585df96F0d0FdE2A9e28c3fC;
        MellowOFTAdapter MBTC 0x5dc6B9Fb10F11a134914c025990A54C3CFEb5154;
        TargetCore MBTC 0x197A5CaE846984F00Ff650b11a31907aEd7B959c;
        MellowOFT MBTC 0xdFCaB55563345Ed11616A377a6ba6189F2B57d4c;
        MultiVault MBTC 0xfc9102b1756f244E4c656844e74c19B00C9FdBDB.

        SourceCore LSK 0x49203fC2cD1924D75BA15Da77C337f8eF332E318;
        MellowOFTAdapter LSK 0x60Ea399d5C03C2aE799093F8fd3F44480BEB1e25.
        TargetCore LSK 0xf2BA9Dab43d5D9014eCA96f058C6dF3945b919bD;
        MellowOFT LSK 0x20347ece0df3B4B413eE656B9FfCc0562285be71;
        MultiVault LSK 0x97Ea34B28535423B51638878B68CAe37e51b0652.
    */

    uint256 public constant EPOCH_DURATION = 1 days;
    uint256 public constant ORACLE_MAX_AGE = 14 days;
    uint256 public constant WITHDRAWAL_DELAY = 15 days;

    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("DEPLOYER_PK")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);

        /*
            SourceCore WSTETH 0x2dE9fa30638960580dbFFece296333e5ca8Cb255;
            MellowOFTAdapter WSTETH 0xA1e96AE1Af42EBF3E3D8738c576d2fD57c02e05b;
            TargetCore WSTETH 0xb58D06eCC39cD6955542861d4374845Ed2014140;
            MellowOFT WSTETH 0x7f98073e7234B7c7F9d0223168dBCd95feAfba58;
            MultiVault WSTETH 0x176209cBD27CF9DF26d2A971E6649417Cb3F9b7F.
        */
        {
            SourceCore sourceCore = SourceCore(0x2dE9fa30638960580dbFFece296333e5ca8Cb255);
            address targetCoreAddress = 0xb58D06eCC39cD6955542861d4374845Ed2014140;
            uint32 targetEid = Constants.endpointId(Constants.ETHEREUM_CHAINID);
            MellowOFTAdapter mellowOFTAdapter = MellowOFTAdapter(0xA1e96AE1Af42EBF3E3D8738c576d2fD57c02e05b);
            MellowOFT mellowOFT = MellowOFT(0x7f98073e7234B7c7F9d0223168dBCd95feAfba58);

            InitSource.init(
                InitSource.InitParams({
                    deployer: deployer,
                    vaultAdmin: Constants.LISK_ADMIN(),
                    vaultProxyAdmin: Constants.LISK_PROXY_ADMIN(),
                    oracleUpdater: Constants.LISK_ORACLE_UPDATER(),
                    curatorAdmin: Constants.LISK_CURATOR_ADMIN(),
                    curatorOperator: Constants.LISK_CURATOR_OPERATOR(),
                    sourceCore: sourceCore,
                    targetEid: targetEid,
                    targetCoreAddress: targetCoreAddress,
                    mellowOFTAdapter: mellowOFTAdapter,
                    mellowOFT: mellowOFT,
                    name: "Lisk wstETH Vault",
                    symbol: "lskETH",
                    epochDuration: EPOCH_DURATION,
                    limit: 1000 ether,
                    oracleMaxAge: ORACLE_MAX_AGE,
                    withdrawalDelay: WITHDRAWAL_DELAY
                })
            );
        }

        /*
            SourceCore MBTC 0xAe2b785bbBE30755585df96F0d0FdE2A9e28c3fC;
            MellowOFTAdapter MBTC 0x5dc6B9Fb10F11a134914c025990A54C3CFEb5154;
            TargetCore MBTC 0x197A5CaE846984F00Ff650b11a31907aEd7B959c;
            MellowOFT MBTC 0xdFCaB55563345Ed11616A377a6ba6189F2B57d4c;
            MultiVault MBTC 0xfc9102b1756f244E4c656844e74c19B00C9FdBDB.
        */
        {
            SourceCore sourceCore = SourceCore(0xAe2b785bbBE30755585df96F0d0FdE2A9e28c3fC);
            address targetCoreAddress = 0x197A5CaE846984F00Ff650b11a31907aEd7B959c;
            uint32 targetEid = Constants.endpointId(Constants.ETHEREUM_CHAINID);
            MellowOFTAdapter mellowOFTAdapter = MellowOFTAdapter(0x5dc6B9Fb10F11a134914c025990A54C3CFEb5154);
            MellowOFT mellowOFT = MellowOFT(0xdFCaB55563345Ed11616A377a6ba6189F2B57d4c);

            InitSource.init(
                InitSource.InitParams({
                    deployer: deployer,
                    vaultAdmin: Constants.LISK_ADMIN(),
                    vaultProxyAdmin: Constants.LISK_PROXY_ADMIN(),
                    oracleUpdater: Constants.LISK_ORACLE_UPDATER(),
                    curatorAdmin: Constants.LISK_CURATOR_ADMIN(),
                    curatorOperator: Constants.LISK_CURATOR_OPERATOR(),
                    sourceCore: sourceCore,
                    targetEid: targetEid,
                    targetCoreAddress: targetCoreAddress,
                    mellowOFTAdapter: mellowOFTAdapter,
                    mellowOFT: mellowOFT,
                    name: "Lisk rsmBTC Vault",
                    symbol: "rsM-BTC",
                    epochDuration: EPOCH_DURATION,
                    limit: 100 ether,
                    oracleMaxAge: ORACLE_MAX_AGE,
                    withdrawalDelay: WITHDRAWAL_DELAY
                })
            );
        }

        /*  
            SourceCore LSK 0x49203fC2cD1924D75BA15Da77C337f8eF332E318;
            MellowOFTAdapter LSK 0x60Ea399d5C03C2aE799093F8fd3F44480BEB1e25.
            TargetCore LSK 0xf2BA9Dab43d5D9014eCA96f058C6dF3945b919bD;
            MellowOFT LSK 0x20347ece0df3B4B413eE656B9FfCc0562285be71;
            MultiVault LSK 0x97Ea34B28535423B51638878B68CAe37e51b0652.
        */
        {
            SourceCore sourceCore = SourceCore(0x49203fC2cD1924D75BA15Da77C337f8eF332E318);
            address targetCoreAddress = 0xf2BA9Dab43d5D9014eCA96f058C6dF3945b919bD;
            uint32 targetEid = Constants.endpointId(Constants.ETHEREUM_CHAINID);
            MellowOFTAdapter mellowOFTAdapter = MellowOFTAdapter(0x60Ea399d5C03C2aE799093F8fd3F44480BEB1e25);
            MellowOFT mellowOFT = MellowOFT(0x20347ece0df3B4B413eE656B9FfCc0562285be71);

            InitSource.init(
                InitSource.InitParams({
                    deployer: deployer,
                    vaultAdmin: Constants.LISK_ADMIN(),
                    vaultProxyAdmin: Constants.LISK_PROXY_ADMIN(),
                    oracleUpdater: Constants.LISK_ORACLE_UPDATER(),
                    curatorAdmin: Constants.LISK_CURATOR_ADMIN(),
                    curatorOperator: Constants.LISK_CURATOR_OPERATOR(),
                    sourceCore: sourceCore,
                    targetEid: targetEid,
                    targetCoreAddress: targetCoreAddress,
                    mellowOFTAdapter: mellowOFTAdapter,
                    mellowOFT: mellowOFT,
                    name: "Lisk LSK Vault",
                    symbol: "rsLSK",
                    epochDuration: EPOCH_DURATION,
                    limit: 10e6 ether,
                    oracleMaxAge: ORACLE_MAX_AGE,
                    withdrawalDelay: WITHDRAWAL_DELAY
                })
            );
        }

        vm.stopBroadcast();

        // revert("OK");
    }
}
