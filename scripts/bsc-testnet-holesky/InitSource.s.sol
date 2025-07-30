// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/InitSource.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    /*
        [bsc-testnet] SourceCore implementation 0x74A73c6Fed2c51F875C3df0C689AD1D6C31D042D;
        [holesky] TargetCore implementation 0x302F7129f7f4a5b25B5b96F12175cb05c3A3119D;

        [bsc-testnet] SourceCore CYC 0xA428eC4613C61Ee69bE455c518740888667E9629;
        [bsc-testnet] MellowOFTAdapter CYC 0xDf0aE8ABD2b8D7021c65e0167c8bF8ABEf24b41E.
        [holesky] TargetCore CYC 0xE2cB1199bEcDbb0D1daC132592d4DedeeEADC74c;
        [holesky] MellowOFT CYC 0xEb8460a5f2c1796Fc362756A9755AD75295b094c.
    */

    uint256 public constant EPOCH_DURATION = 1 days;
    uint256 public constant ORACLE_MAX_AGE = 14 days;
    uint256 public constant WITHDRAWAL_DELAY = 15 days;

    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);
        {
            SourceCore sourceCore = SourceCore(0xA428eC4613C61Ee69bE455c518740888667E9629);
            address targetCoreAddress = 0xE2cB1199bEcDbb0D1daC132592d4DedeeEADC74c;
            uint32 targetEid = Constants.endpointId(Constants.HOLESKY_CHAINID);
            MellowOFTAdapter mellowOFTAdapter = MellowOFTAdapter(0xDf0aE8ABD2b8D7021c65e0167c8bF8ABEf24b41E);
            MellowOFT mellowOFT = MellowOFT(0xEb8460a5f2c1796Fc362756A9755AD75295b094c);

            InitSource.init(
                InitSource.InitParams({
                    deployer: deployer,
                    vaultAdmin: Constants.BSC_TESTNET_VAULT_ADMIN(),
                    vaultProxyAdmin: Constants.BSC_TESTNET_VAULT_PROXY_ADMIN(),
                    oracleUpdater: Constants.BSC_TESTNET_VAULT_ADMIN(),
                    curatorAdmin: Constants.CYCLE_CURATOR(),
                    curatorOperator: Constants.CYCLE_CURATOR(),
                    sourceCore: sourceCore,
                    targetEid: targetEid,
                    targetCoreAddress: targetCoreAddress,
                    mellowOFTAdapter: mellowOFTAdapter,
                    mellowOFT: mellowOFT,
                    name: "Cycle Test Interop Vault",
                    symbol: "CYC-TIV",
                    epochDuration: EPOCH_DURATION,
                    limit: 100 ether,
                    oracleMaxAge: ORACLE_MAX_AGE,
                    withdrawalDelay: WITHDRAWAL_DELAY
                })
            );
        }
        vm.stopBroadcast();
        // revert("ok");
    }
}
