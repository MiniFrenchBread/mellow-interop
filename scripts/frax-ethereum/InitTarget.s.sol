// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/InitTarget.sol";

import {IMultiVault, MultiVault} from "@mellow-finance/simple-lrt/vaults/MultiVault.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    /*
        SourceCore FRAX 0x24dD1eaBEad7b3cB07b7d162439ec0A4EEC703DF;
        MellowOFTAdapter FRAX 0x24E6D68a553BA3146E10CDb06e9dB996Cea2bbBa.
        TargetCore FRAX 0x6408a5261578E17f858ADD039dEb72E1952E9Fe9;
        MellowOFT FRAX 0xf85932AcE734E3CF04b5c2a6Cb7B10f44014eCb9.
        MultiVault FRAX: 0x5B2099e204f22A0ccE3806fc2093713E2780D437.
    */

    address claimer = 0x25024a3017B8da7161d8c5DCcF768F8678fB5802;

    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);
        uint32 sourceEid = Constants.endpointId(Constants.FRAX_CHAINID);
        {
            SourceCore sourceCore = SourceCore(0x24dD1eaBEad7b3cB07b7d162439ec0A4EEC703DF);
            TargetCore targetCore = TargetCore(0x6408a5261578E17f858ADD039dEb72E1952E9Fe9);
            MellowOFTAdapter mellowOFTAdapter = MellowOFTAdapter(0x24E6D68a553BA3146E10CDb06e9dB996Cea2bbBa);
            MellowOFT mellowOFT = MellowOFT(0xf85932AcE734E3CF04b5c2a6Cb7B10f44014eCb9);
            address vault = 0x5B2099e204f22A0ccE3806fc2093713E2780D437;
            InitTarget.init(
                InitTarget.InitParams({
                    targetCore: targetCore,
                    sourceEid: sourceEid,
                    sourceCoreAddress: address(sourceCore),
                    mellowOFT: mellowOFT,
                    mellowOFTAdapter: address(mellowOFTAdapter),
                    deployer: deployer,
                    vaultAdmin: Constants.ETHEREUM_ADMIN(),
                    vaultProxyAdmin: Constants.ETHEREUM_PROXY_ADMIN(),
                    curatorAdmin: Constants.ETHEREUM_CURATOR_ADMIN(),
                    curatorOperator: Constants.ETHEREUM_CURATOR_OPERATOR(),
                    vault: address(vault),
                    claimer: claimer
                })
            );
        }

        vm.stopBroadcast();
        // revert("ok");
    }
}
