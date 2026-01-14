// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/InitTarget.sol";

import "./Params.sol";
import {IMultiVault, MultiVault} from "@mellow-finance/simple-lrt/vaults/MultiVault.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        assertTrue(Params.sourceCore != address(0), "SourceCore address is not set");
        assertTrue(Params.targetCore != address(0), "TargetCore address is not set");
        assertTrue(Params.mellowOFTAdapter != address(0), "MellowOFTAdapter address is not set");
        assertTrue(Params.mellowOFT != address(0), "MellowOFT address is not set");
        assertTrue(Params.targetVault != address(0), "TargetVault address is not set");

        vm.startBroadcast(deployerPk);
        {
            InitTarget.init(
                InitTarget.InitParams({
                    targetCore: TargetCore(Params.targetCore),
                    sourceEid: Constants.endpointId(Params.sourceChainId),
                    sourceCoreAddress: Params.sourceCore,
                    mellowOFT: MellowOFT(Params.mellowOFT),
                    mellowOFTAdapter: Params.mellowOFTAdapter,
                    deployer: deployer,
                    vaultAdmin: Params.vaultAdmin,
                    vaultProxyAdmin: Params.vaultProxyAdmin,
                    curatorAdmin: Params.curator,
                    curatorOperator: Params.operator,
                    vault: Params.targetVault,
                    claimer: Params.claimer
                })
            );
        }

        vm.stopBroadcast();
        //revert("ok");
    }
}
