// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/InitSource.sol";
import "./Params.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        require(Params.sourceCore != address(0), "SourceCore address is not set");
        require(Params.targetCore != address(0), "TargetCore address is not set");
        require(Params.mellowOFTAdapter != address(0), "MellowOFTAdapter address is not set");
        require(Params.mellowOFT != address(0), "MellowOFT address is not set");

        uint32 targetEid = Constants.endpointId(Params.targetChainId);
        console2.log("Target endpoint ID %s", targetEid);

        vm.startBroadcast(deployerPk);
        {
            InitSource.init(
                InitSource.InitParams({
                    deployer: deployer,
                    vaultAdmin: Params.vaultAdmin,
                    vaultProxyAdmin: Params.proxyAdmin,
                    oracleUpdater: Params.vaultAdmin,
                    curatorAdmin: Params.curator,
                    curatorOperator: Params.operator,
                    sourceCore: SourceCore(Params.sourceCore),
                    targetEid: targetEid,
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
        //revert("ok");
    }
}
