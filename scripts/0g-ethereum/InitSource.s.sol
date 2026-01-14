// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/InitSource.sol";
import "./Params.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        assertTrue(Params.sourceCore != address(0), "SourceCore address is not set");
        assertTrue(Params.targetCore != address(0), "TargetCore address is not set");
        assertTrue(Params.mellowOFTAdapter != address(0), "MellowOFTAdapter address is not set");
        assertTrue(Params.mellowOFT != address(0), "MellowOFT address is not set");

        vm.startBroadcast(deployerPk);
        {
            InitSource.init(
                InitSource.InitParams({
                    deployer: deployer,
                    vaultAdmin: Params.vaultAdmin,
                    vaultProxyAdmin: Params.vaultProxyAdmin,
                    oracleUpdater: Params.vaultAdmin,
                    curatorAdmin: Params.curator,
                    curatorOperator: Params.operator,
                    sourceCore: SourceCore(Params.sourceCore),
                    targetEid: Constants.endpointId(Params.targetChainId),
                    targetCoreAddress: Params.targetCore,
                    mellowOFTAdapter: MellowOFTAdapter(Params.mellowOFTAdapter),
                    mellowOFT: MellowOFT(Params.mellowOFT),
                    name: Params.vaultName,
                    symbol: Params.vaultSymbol,
                    epochDuration: Params.EPOCH_DURATION,
                    limit: type(uint256).max / 2,
                    oracleMaxAge: Params.ORACLE_MAX_AGE,
                    withdrawalDelay: Params.WITHDRAWAL_DELAY
                })
            );
        }
        vm.stopBroadcast();
        // revert("ok");
    }
}
