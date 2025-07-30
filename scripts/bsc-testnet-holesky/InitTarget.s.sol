// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/InitTarget.sol";

import {IMultiVault, MultiVault} from "@mellow-finance/simple-lrt/vaults/MultiVault.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    /*
        [bsc-testnet] SourceCore CYC 0xA428eC4613C61Ee69bE455c518740888667E9629;
        [bsc-testnet] MellowOFTAdapter CYC 0xDf0aE8ABD2b8D7021c65e0167c8bF8ABEf24b41E.
        [holesky] TargetCore CYC 0xE2cB1199bEcDbb0D1daC132592d4DedeeEADC74c;
        [holesky] MellowOFT CYC 0xEb8460a5f2c1796Fc362756A9755AD75295b094c.
        [holesky] MultiVault CYC 0x412F4fD76622F92F37Ab731BA256b51FF593e806.
    */

    address claimer = 0x74A73c6Fed2c51F875C3df0C689AD1D6C31D042D;

    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);
        uint32 sourceEid = Constants.endpointId(Constants.BSC_TESTNET_CHAINID);
        {
            SourceCore sourceCore = SourceCore(0xA428eC4613C61Ee69bE455c518740888667E9629);
            TargetCore targetCore = TargetCore(0xE2cB1199bEcDbb0D1daC132592d4DedeeEADC74c);
            MellowOFTAdapter mellowOFTAdapter = MellowOFTAdapter(0xDf0aE8ABD2b8D7021c65e0167c8bF8ABEf24b41E);
            MellowOFT mellowOFT = MellowOFT(0xEb8460a5f2c1796Fc362756A9755AD75295b094c);
            address vault = 0x412F4fD76622F92F37Ab731BA256b51FF593e806;
            InitTarget.init(
                InitTarget.InitParams({
                    targetCore: targetCore,
                    sourceEid: sourceEid,
                    sourceCoreAddress: address(sourceCore),
                    mellowOFT: mellowOFT,
                    mellowOFTAdapter: address(mellowOFTAdapter),
                    deployer: deployer,
                    vaultAdmin: Constants.HOLESKY_CYCLE_VAULT_ADMIN(),
                    vaultProxyAdmin: Constants.HOLESKY_CYCLE_VAULT_PROXY_ADMIN(),
                    curatorAdmin: Constants.CYCLE_CURATOR(),
                    curatorOperator: Constants.CYCLE_CURATOR(),
                    vault: address(vault),
                    claimer: claimer
                })
            );
        }

        vm.stopBroadcast();
        // revert("ok");
    }
}
