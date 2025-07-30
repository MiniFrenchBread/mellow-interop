// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/InitSource.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    /*
        [bsc] SourceCore CYC 0xc8e046fe778BE29572016d1f703e9B2ff77a207D;
        [bsc] MellowOFTAdapter CYC 0x2aE580d09efF4E178B62fC30DB3482bB36fB9E71.
        [ethereum] TargetCore CYC 0xAdEcB7647C3370A40c9F06FB8F5F709c87324932;
        [ethereum] MellowOFT CYC 0x05E979fdcEb5A82F963468A3f1e4c7cCf6957c84.
    */

    uint256 public constant EPOCH_DURATION = 1 days;
    uint256 public constant ORACLE_MAX_AGE = 14 days;
    uint256 public constant WITHDRAWAL_DELAY = 15 days;

    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);
        {
            SourceCore sourceCore = SourceCore(0xc8e046fe778BE29572016d1f703e9B2ff77a207D);
            address targetCoreAddress = 0xAdEcB7647C3370A40c9F06FB8F5F709c87324932;
            uint32 targetEid = Constants.endpointId(Constants.ETHEREUM_CHAINID);
            MellowOFTAdapter mellowOFTAdapter = MellowOFTAdapter(0x2aE580d09efF4E178B62fC30DB3482bB36fB9E71);
            MellowOFT mellowOFT = MellowOFT(0x05E979fdcEb5A82F963468A3f1e4c7cCf6957c84);

            InitSource.init(
                InitSource.InitParams({
                    deployer: deployer,
                    vaultAdmin: Constants.CYCLE_MAINNET_VAULT_ADMIN(),
                    vaultProxyAdmin: Constants.CYCLE_MAINNET_VAULT_PROXY_ADMIN(),
                    oracleUpdater: Constants.CYCLE_MAINNET_VAULT_ADMIN(),
                    curatorAdmin: Constants.CYCLE_MAINNET_CURATOR(),
                    curatorOperator: Constants.CYCLE_MAINNET_CURATOR(),
                    sourceCore: sourceCore,
                    targetEid: targetEid,
                    targetCoreAddress: targetCoreAddress,
                    mellowOFTAdapter: mellowOFTAdapter,
                    mellowOFT: mellowOFT,
                    name: "CycleNetwork Vault",
                    symbol: "CYC",
                    epochDuration: EPOCH_DURATION,
                    limit: type(uint256).max,
                    oracleMaxAge: ORACLE_MAX_AGE,
                    withdrawalDelay: WITHDRAWAL_DELAY
                })
            );
        }
        vm.stopBroadcast();
        // revert("ok");
    }
}
