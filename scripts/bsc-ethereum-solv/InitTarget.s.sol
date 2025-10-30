// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/InitTarget.sol";

import {IMultiVault, MultiVault} from "@mellow-finance/simple-lrt/vaults/MultiVault.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    /*
        [bsc] SourceCore SOLV 0x7C942105Be8Be5B3cbB7309120b0C0C16ee3e536;
        [bsc] MellowOFTAdapter SOLV 0xAEa7F7bF3A3b40e625b160e21473dAC1D6089DD9.
        [ethereum] TargetCore SOLV 0x927F0604c60924399EB44f54C4c333Ed1Ef21B45;
        [ethereum] MellowOFT SOLV 0x080cCaa313B0e0Bac744C090B5894d75d853518D.
        [ethereum] MultiVault SOLV 0x5f08FcD1f1dAB34738200EE30E0Ba3D3289ec1A6;
    */

    address claimer = 0x25024a3017B8da7161d8c5DCcF768F8678fB5802;

    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);
        uint32 sourceEid = Constants.endpointId(Constants.BSC_CHAINID);
        {
            SourceCore sourceCore = SourceCore(0x7C942105Be8Be5B3cbB7309120b0C0C16ee3e536);
            TargetCore targetCore = TargetCore(0x927F0604c60924399EB44f54C4c333Ed1Ef21B45);
            MellowOFTAdapter mellowOFTAdapter = MellowOFTAdapter(0xAEa7F7bF3A3b40e625b160e21473dAC1D6089DD9);
            MellowOFT mellowOFT = MellowOFT(0x080cCaa313B0e0Bac744C090B5894d75d853518D);
            address vault = 0x5f08FcD1f1dAB34738200EE30E0Ba3D3289ec1A6;
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
