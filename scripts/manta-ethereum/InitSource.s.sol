// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/InitSource.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    /*
        [manta] SourceCore MANTA 0x9cD45b6E33433ED50738F508aD378b567603f61F
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
            SourceCore sourceCore = SourceCore(0x9cD45b6E33433ED50738F508aD378b567603f61F);
            address targetCoreAddress = 0x48E69cB6c6F05e194589BE37408c5717E7cCE1C7;
            uint32 targetEid = Constants.endpointId(Constants.ETHEREUM_CHAINID);
            MellowOFTAdapter mellowOFTAdapter = MellowOFTAdapter(0x9D9645c761151fA4B390A0e79f63Ba356fF1870a);
            MellowOFT mellowOFT = MellowOFT(0xF3A1C44d1825Fb49d633F681Cb2B4e7dE2e071D4);

            InitSource.init(
                InitSource.InitParams({
                    deployer: deployer,
                    vaultAdmin: Constants.MANTA_SOURCE_VAULT_ADMIN(),
                    vaultProxyAdmin: Constants.MANTA_SOURCE_VAULT_PROXY_ADMIN(),
                    oracleUpdater: Constants.MANTA_SOURCE_ORACLE_UPDATER(),
                    curatorAdmin: Constants.MANTA_SOURCE_CURATOR(),
                    curatorOperator: Constants.MANTA_SOURCE_CURATOR_OPERATOR(),
                    sourceCore: sourceCore,
                    targetEid: targetEid,
                    targetCoreAddress: targetCoreAddress,
                    mellowOFTAdapter: mellowOFTAdapter,
                    mellowOFT: mellowOFT,
                    name: "Manta Restaking Vault",
                    symbol: "mstManta",
                    epochDuration: EPOCH_DURATION,
                    limit: 20e6 ether,
                    oracleMaxAge: ORACLE_MAX_AGE,
                    withdrawalDelay: WITHDRAWAL_DELAY
                })
            );
        }
        
        console2.log("Vault Proxy admin MANTA       %s", Constants.MANTA_SOURCE_VAULT_PROXY_ADMIN());
        console2.log("Vault Admin MANTA             %s", Constants.MANTA_SOURCE_VAULT_ADMIN());
        console2.log("Curator Admin MANTA           %s", Constants.MANTA_SOURCE_CURATOR());
        console2.log("Curator Operator MANTA        %s", Constants.MANTA_SOURCE_CURATOR_OPERATOR());
        console2.log("Curator Oracle updater MANTA  %s", Constants.MANTA_SOURCE_ORACLE_UPDATER());
        vm.stopBroadcast();
        revert("ok");
    }
}
