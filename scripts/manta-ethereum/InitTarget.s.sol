// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/InitTarget.sol";

import {IMultiVault, MultiVault} from "@mellow-finance/simple-lrt/vaults/MultiVault.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    /*
        [manta] SourceCore MANTA 0x9cD45b6E33433ED50738F508aD378b567603f61F
        [manta] MellowOFTAdapter MANTA 0x9D9645c761151fA4B390A0e79f63Ba356fF1870a
        [ethereum] TargetCore MANTA 0x48E69cB6c6F05e194589BE37408c5717E7cCE1C7
        [ethereum] MellowOFT MANTA 0xF3A1C44d1825Fb49d633F681Cb2B4e7dE2e071D4
        [ethereum] MultiVault MANTA address(0)
    */

    address claimer = 0x25024a3017B8da7161d8c5DCcF768F8678fB5802;

    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);
        uint32 sourceEid = Constants.endpointId(Constants.MANTA_CHAINID);
        {
            SourceCore sourceCore = SourceCore(0x9cD45b6E33433ED50738F508aD378b567603f61F);
            TargetCore targetCore = TargetCore(0x48E69cB6c6F05e194589BE37408c5717E7cCE1C7);
            MellowOFTAdapter mellowOFTAdapter = MellowOFTAdapter(0x9D9645c761151fA4B390A0e79f63Ba356fF1870a);
            MellowOFT mellowOFT = MellowOFT(0xF3A1C44d1825Fb49d633F681Cb2B4e7dE2e071D4);
            address vault = address(0);
            InitTarget.init(
                InitTarget.InitParams({
                    targetCore: targetCore,
                    sourceEid: sourceEid,
                    sourceCoreAddress: address(sourceCore),
                    mellowOFT: mellowOFT,
                    mellowOFTAdapter: address(mellowOFTAdapter),
                    deployer: deployer,
                    vaultAdmin: Constants.MANTA_TARGET_VAULT_ADMIN(),
                    vaultProxyAdmin: Constants.MANTA_TARGET_VAULT_PROXY_ADMIN(),
                    curatorAdmin: Constants.MANTA_TARGET_CURATOR(),
                    curatorOperator: Constants.MANTA_TARGET_CURATOR_OPERATOR(),
                    vault: address(vault),
                    claimer: claimer
                })
            );
        }
        console2.log("Vault Proxy admin MANTA       %s", Constants.MANTA_TARGET_VAULT_PROXY_ADMIN());
        console2.log("Vault Admin MANTA             %s", Constants.MANTA_TARGET_VAULT_ADMIN());
        console2.log("Curator Admin MANTA           %s", Constants.MANTA_TARGET_CURATOR());
        console2.log("Curator Operator MANTA        %s", Constants.MANTA_TARGET_CURATOR_OPERATOR());

        vm.stopBroadcast();
        revert("ok");
    }
}
