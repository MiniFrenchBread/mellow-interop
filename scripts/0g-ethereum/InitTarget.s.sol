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

        require(Params.sourceCore != address(0), "SourceCore address is not set");
        require(Params.targetCore != address(0), "TargetCore address is not set");
        require(Params.mellowOFTAdapter != address(0), "MellowOFTAdapter address is not set");
        require(Params.mellowOFT != address(0), "MellowOFT address is not set");
        require(Params.targetVault != address(0), "TargetVault address is not set");

        uint32 sourceEid = Constants.endpointId(Params.sourceChainId);
        console2.log("Source endpoint ID %s", sourceEid);

        vm.startBroadcast(deployerPk);
        {
            InitTarget.init(
                InitTarget.InitParams({
                    targetCore: TargetCore(Params.targetCore),
                    sourceEid: sourceEid,
                    sourceCoreAddress: Params.sourceCore,
                    mellowOFT: MellowOFT(Params.mellowOFT),
                    mellowOFTAdapter: Params.mellowOFTAdapter,
                    deployer: deployer,
                    vaultAdmin: Params.vaultAdmin,
                    vaultProxyAdmin: Params.proxyAdmin,
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
