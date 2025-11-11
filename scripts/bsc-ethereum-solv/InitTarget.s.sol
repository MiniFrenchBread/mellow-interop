// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/InitTarget.sol";

import {IMultiVault, MultiVault} from "@mellow-finance/simple-lrt/vaults/MultiVault.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    /*
        [bsc] SourceCore SOLV 0x01C56d641c7dCE4F43679a807DD3b69872Ce8e3C;
        [bsc] MellowOFTAdapter SOLV 0xb51Fb298A55E2680da480cE97c08fB39B8a5570A.
        [ethereum] TargetCore SOLV 0x8545a1BaaDDdff45fBc316D80851214739189471;
        [ethereum] MellowOFT SOLV 0x7670d08147D345f19a00EdC02D2399531b6EF91D.
        [ethereum] MultiVault SOLV 0xdFFee0Fcbf7F900483E4E01FcD5C678c6E932023;
    */

    address claimer = 0x25024a3017B8da7161d8c5DCcF768F8678fB5802;

    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);
        uint32 sourceEid = Constants.endpointId(Constants.BSC_CHAINID);
        {
            SourceCore sourceCore = SourceCore(0x01C56d641c7dCE4F43679a807DD3b69872Ce8e3C);
            TargetCore targetCore = TargetCore(0x8545a1BaaDDdff45fBc316D80851214739189471);
            MellowOFTAdapter mellowOFTAdapter = MellowOFTAdapter(0xb51Fb298A55E2680da480cE97c08fB39B8a5570A);
            MellowOFT mellowOFT = MellowOFT(0x7670d08147D345f19a00EdC02D2399531b6EF91D);
            address vault = 0xdFFee0Fcbf7F900483E4E01FcD5C678c6E932023;
            InitTarget.init(
                InitTarget.InitParams({
                    targetCore: targetCore,
                    sourceEid: sourceEid,
                    sourceCoreAddress: address(sourceCore),
                    mellowOFT: mellowOFT,
                    mellowOFTAdapter: address(mellowOFTAdapter),
                    deployer: deployer,
                    vaultAdmin: Constants.SOLV_MAINNET_VAULT_ADMIN(),
                    vaultProxyAdmin: Constants.SOLV_MAINNET_VAULT_PROXY_ADMIN(),
                    curatorAdmin: Constants.SOLV_MAINNET_CURATOR(),
                    curatorOperator: Constants.SOLV_MAINNET_CURATOR_OPERATOR(),
                    vault: address(vault),
                    claimer: claimer
                })
            );
        }

        vm.stopBroadcast();
        // revert("ok");
    }
}
