// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/InitTarget.sol";

import {IMultiVault, MultiVault} from "@mellow-finance/simple-lrt/vaults/MultiVault.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    struct CoreDeployment {
        uint256 sourceChainId;
        address SourceCore;
        address SourceMellowOFTAdapter;
        address TargetCore;
        address TargetMellowOFT;
        address TargetMultiVault;
    }

    address claimer = Constants.OG_MAINNET_CURATOR_OPERATOR();

    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        CoreDeployment memory coreDeployment = CoreDeployment({
            sourceChainId: Constants.GALILEO_CHAINID,
            SourceCore: 0xc07510228bB180985C6009C24ED5D05fdfC82F84, // [OG] SourceCore OG
            SourceMellowOFTAdapter: 0xA83067d29b9671eECbDb9A3290ded33c63659b99, // [OG] MellowOFTAdapter OG
            TargetCore: 0xD48b09Fc5fB2c3C8a24DD67e90542a8f443BA21b, // [sepolia] TargetCore OG
            TargetMellowOFT: 0x4fed2B4d6c797f22026283a7a10A14B86Bd0636C, // [sepolia] MellowOFT OG
            TargetMultiVault: 0x6908E3Ae07178dc58CCdc18FFCFc9953beEda0a2 // [sepolia] MultiVault OG
        });

        vm.startBroadcast(deployerPk);
        {
            InitTarget.init(
                InitTarget.InitParams({
                    targetCore: TargetCore(coreDeployment.TargetCore),
                    sourceEid: Constants.endpointId(coreDeployment.sourceChainId),
                    sourceCoreAddress: coreDeployment.SourceCore,
                    mellowOFT: MellowOFT(coreDeployment.TargetMellowOFT),
                    mellowOFTAdapter: coreDeployment.SourceMellowOFTAdapter,
                    deployer: deployer,
                    vaultAdmin: Constants.OG_MAINNET_VAULT_ADMIN(),
                    vaultProxyAdmin: Constants.OG_MAINNET_VAULT_PROXY_ADMIN(),
                    curatorAdmin: Constants.OG_MAINNET_CURATOR(),
                    curatorOperator: Constants.OG_MAINNET_CURATOR_OPERATOR(),
                    vault: coreDeployment.TargetMultiVault,
                    claimer: claimer
                })
            );
        }

        vm.stopBroadcast();
        //revert("ok");
    }
}
