// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/InitTarget.sol";

import {IMultiVault, MultiVault} from "@mellow-finance/simple-lrt/vaults/MultiVault.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    /*
        [bsc] SourceCore CYC 0xc8e046fe778BE29572016d1f703e9B2ff77a207D;
        [bsc] MellowOFTAdapter CYC 0x2aE580d09efF4E178B62fC30DB3482bB36fB9E71.
        [ethereum] TargetCore CYC 0xAdEcB7647C3370A40c9F06FB8F5F709c87324932;
        [ethereum] MellowOFT CYC 0x05E979fdcEb5A82F963468A3f1e4c7cCf6957c84.
        [ethereum] MultiVault CYC 0x8Eb26Ae16ceD27f46c717d0E2dF070c370d65261;
    */

    address claimer = 0x25024a3017B8da7161d8c5DCcF768F8678fB5802;

    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);
        uint32 sourceEid = Constants.endpointId(Constants.BSC_CHAINID);
        {
            SourceCore sourceCore = SourceCore(0xc8e046fe778BE29572016d1f703e9B2ff77a207D);
            TargetCore targetCore = TargetCore(0xAdEcB7647C3370A40c9F06FB8F5F709c87324932);
            MellowOFTAdapter mellowOFTAdapter = MellowOFTAdapter(0x2aE580d09efF4E178B62fC30DB3482bB36fB9E71);
            MellowOFT mellowOFT = MellowOFT(0x05E979fdcEb5A82F963468A3f1e4c7cCf6957c84);
            address vault = 0x8Eb26Ae16ceD27f46c717d0E2dF070c370d65261;
            InitTarget.init(
                InitTarget.InitParams({
                    targetCore: targetCore,
                    sourceEid: sourceEid,
                    sourceCoreAddress: address(sourceCore),
                    mellowOFT: mellowOFT,
                    mellowOFTAdapter: address(mellowOFTAdapter),
                    deployer: deployer,
                    vaultAdmin: Constants.CYCLE_MAINNET_VAULT_ADMIN(),
                    vaultProxyAdmin: Constants.CYCLE_MAINNET_VAULT_PROXY_ADMIN(),
                    curatorAdmin: Constants.CYCLE_MAINNET_CURATOR(),
                    curatorOperator: Constants.CYCLE_MAINNET_CURATOR(),
                    vault: address(vault),
                    claimer: claimer
                })
            );
        }

        vm.stopBroadcast();
        // revert("ok");
    }
}
