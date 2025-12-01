// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/InitSource.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    struct CoreDeployment {
        uint256 targetChainId;
        address SourceCore;
        address SourceMellowOFTAdapter;
        address TargetCore;
        address TargetMellowOFT;
    }

    uint256 public constant EPOCH_DURATION = 1 days;
    uint256 public constant ORACLE_MAX_AGE = 21 days;
    uint256 public constant WITHDRAWAL_DELAY = 22 days;

    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        CoreDeployment memory coreDeployment = CoreDeployment({
            targetChainId: Constants.SEPOLIA_CHAINID,
            SourceCore: 0xc07510228bB180985C6009C24ED5D05fdfC82F84, // [OG] SourceCore OG
            SourceMellowOFTAdapter: 0xA83067d29b9671eECbDb9A3290ded33c63659b99, // [OG] MellowOFTAdapter OG
            TargetCore: 0xD48b09Fc5fB2c3C8a24DD67e90542a8f443BA21b, // [sepolia] TargetCore OG
            TargetMellowOFT: 0x4fed2B4d6c797f22026283a7a10A14B86Bd0636C // [sepolia] MellowOFT OG
        });

        vm.startBroadcast(deployerPk);
        {
            InitSource.init(
                InitSource.InitParams({
                    deployer: deployer,
                    vaultAdmin: Constants.OG_MAINNET_VAULT_ADMIN(),
                    vaultProxyAdmin: Constants.OG_MAINNET_VAULT_PROXY_ADMIN(),
                    oracleUpdater: Constants.OG_MAINNET_VAULT_ADMIN(),
                    curatorAdmin: Constants.OG_MAINNET_CURATOR(),
                    curatorOperator: Constants.OG_MAINNET_CURATOR_OPERATOR(),
                    sourceCore: SourceCore(coreDeployment.SourceCore),
                    targetEid: Constants.endpointId(coreDeployment.targetChainId),
                    targetCoreAddress: coreDeployment.TargetCore,
                    mellowOFTAdapter: MellowOFTAdapter(coreDeployment.SourceMellowOFTAdapter),
                    mellowOFT: MellowOFT(coreDeployment.TargetMellowOFT),
                    name: "Staked OG",
                    symbol: "stOG",
                    epochDuration: EPOCH_DURATION,
                    limit: type(uint256).max / 2,
                    oracleMaxAge: ORACLE_MAX_AGE,
                    withdrawalDelay: WITHDRAWAL_DELAY
                })
            );
        }
        vm.stopBroadcast();
       // revert("ok");
    }
}
