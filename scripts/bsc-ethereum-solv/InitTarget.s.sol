// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/InitTarget.sol";

import {IMultiVault, MultiVault} from "@mellow-finance/simple-lrt/vaults/MultiVault.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    /*
        [bsc] SourceCore SOLV 0x7C942105Be8Be5B3cbB7309120b0C0C16ee3e536;
        [bsc] MellowOFTAdapter SOLV 0xAEa7F7bF3A3b40e625b160e21473dAC1D6089DD9.
        [ethereum] TargetCore SOLV 0xf1390f694f34bFE1aa651e8a0313fDc485A39132;
        [ethereum] MellowOFT SOLV 0xb79956D87D887Ba850efaFdefe387458f463750c.
        [ethereum] MultiVault SOLV TBD;
    */

    address claimer = 0x25024a3017B8da7161d8c5DCcF768F8678fB5802;

    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);
        uint32 sourceEid = Constants.endpointId(Constants.BSC_CHAINID);
        {
            SourceCore sourceCore = SourceCore(0x7C942105Be8Be5B3cbB7309120b0C0C16ee3e536);
            TargetCore targetCore = TargetCore(0xf1390f694f34bFE1aa651e8a0313fDc485A39132);
            MellowOFTAdapter mellowOFTAdapter = MellowOFTAdapter(0xAEa7F7bF3A3b40e625b160e21473dAC1D6089DD9);
            MellowOFT mellowOFT = MellowOFT(0xb79956D87D887Ba850efaFdefe387458f463750c);
            address vault = address(0);
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
