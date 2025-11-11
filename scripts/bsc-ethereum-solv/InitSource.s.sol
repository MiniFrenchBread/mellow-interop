// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/InitSource.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    /*
        [bsc] SourceCore SOLV 0x01C56d641c7dCE4F43679a807DD3b69872Ce8e3C;
        [bsc] MellowOFTAdapter SOLV 0xb51Fb298A55E2680da480cE97c08fB39B8a5570A.
        [ethereum] TargetCore SOLV 0x8545a1BaaDDdff45fBc316D80851214739189471;
        [ethereum] MellowOFT SOLV 0x7670d08147D345f19a00EdC02D2399531b6EF91D.
    */

    uint256 public constant EPOCH_DURATION = 1 days;
    uint256 public constant ORACLE_MAX_AGE = 21 days;
    uint256 public constant WITHDRAWAL_DELAY = 22 days;

    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);
        {
            SourceCore sourceCore = SourceCore(0x01C56d641c7dCE4F43679a807DD3b69872Ce8e3C);
            address targetCoreAddress = 0x8545a1BaaDDdff45fBc316D80851214739189471;
            uint32 targetEid = Constants.endpointId(Constants.ETHEREUM_CHAINID);
            MellowOFTAdapter mellowOFTAdapter = MellowOFTAdapter(0xb51Fb298A55E2680da480cE97c08fB39B8a5570A);
            MellowOFT mellowOFT = MellowOFT(0x7670d08147D345f19a00EdC02D2399531b6EF91D);

            InitSource.init(
                InitSource.InitParams({
                    deployer: deployer,
                    vaultAdmin: Constants.SOLV_MAINNET_VAULT_ADMIN(),
                    vaultProxyAdmin: Constants.SOLV_MAINNET_VAULT_PROXY_ADMIN(),
                    oracleUpdater: Constants.SOLV_MAINNET_VAULT_ADMIN(),
                    curatorAdmin: Constants.SOLV_MAINNET_CURATOR(),
                    curatorOperator: Constants.SOLV_MAINNET_CURATOR_OPERATOR(),
                    sourceCore: sourceCore,
                    targetEid: targetEid,
                    targetCoreAddress: targetCoreAddress,
                    mellowOFTAdapter: mellowOFTAdapter,
                    mellowOFT: mellowOFT,
                    name: "Staked SOLV",
                    symbol: "stSOLV",
                    epochDuration: EPOCH_DURATION,
                    limit: 550000000 ether, // 550000000 SOLV
                    oracleMaxAge: ORACLE_MAX_AGE,
                    withdrawalDelay: WITHDRAWAL_DELAY
                })
            );
        }
        vm.stopBroadcast();
        // revert("ok");
    }
}
