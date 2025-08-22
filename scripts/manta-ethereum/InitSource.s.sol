// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/InitSource.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    /*
        [manta] SourceCore MANTA 0xEA879dDfD2952Cd23B61E1a59EB4c49216b2147E
        [manta] MellowOFTAdapter MANTA 0x9D9645c761151fA4B390A0e79f63Ba356fF1870a
        [ethereum] TargetCore MANTA 0x48E69cB6c6F05e194589BE37408c5717E7cCE1C7
        [ethereum] MellowOFT MANTA 0xF3A1C44d1825Fb49d633F681Cb2B4e7dE2e071D4
    */
    uint256 public constant EPOCH_DURATION = 1 days;
    uint256 public constant ORACLE_MAX_AGE = 14 days;
    uint256 public constant WITHDRAWAL_DELAY = 15 days;

    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);
        {
            SourceCore sourceCore = SourceCore(0xEA879dDfD2952Cd23B61E1a59EB4c49216b2147E);
            address targetCoreAddress = 0x48E69cB6c6F05e194589BE37408c5717E7cCE1C7;
            uint32 targetEid = Constants.endpointId(Constants.ETHEREUM_CHAINID);
            MellowOFTAdapter mellowOFTAdapter = MellowOFTAdapter(0x9D9645c761151fA4B390A0e79f63Ba356fF1870a);
            MellowOFT mellowOFT = MellowOFT(0xF3A1C44d1825Fb49d633F681Cb2B4e7dE2e071D4);

            InitSource.init(
                InitSource.InitParams({
                    deployer: deployer,
                    vaultAdmin: Constants.MANTA_MAINNET_VAULT_ADMIN(),
                    vaultProxyAdmin: Constants.MANTA_MAINNET_VAULT_PROXY_ADMIN(),
                    oracleUpdater: Constants.MANTA_MAINNET_VAULT_ADMIN(),
                    curatorAdmin: Constants.MANTA_MAINNET_CURATOR(),
                    curatorOperator: Constants.MANTA_CURATOR_OPERATOR(),
                    sourceCore: sourceCore,
                    targetEid: targetEid,
                    targetCoreAddress: targetCoreAddress,
                    mellowOFTAdapter: mellowOFTAdapter,
                    mellowOFT: mellowOFT,
                    name: "Manta Restaking Vault",
                    symbol: "mstManta",
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
