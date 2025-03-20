// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/InitSource.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("TEST_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);
        SourceCore sourceCore = SourceCore(0xeea0Ed9d5A71569fDA65b66C5983011e67C30F8f);
        address targetCoreAddress = 0xeea0Ed9d5A71569fDA65b66C5983011e67C30F8f;
        uint32 targetEid = Constants.endpointId(Constants.ARBITRUM_CHAINID);
        MellowOFTAdapter mellowOFTAdapter = MellowOFTAdapter(0xBefE3a454df68688715A58E8842B0a697A3f0774);
        MellowOFT mellowOFT = MellowOFT(0x5D52954aa43536be08751048de51B44dF1833204);

        InitSource.init(
            sourceCore,
            targetEid,
            targetCoreAddress,
            mellowOFTAdapter,
            mellowOFT,
            deployer,
            deployer,
            deployer,
            "Mellow Test Vault",
            "MTV",
            1 hours,
            100 ether,
            1 weeks
        );

        vm.stopBroadcast();

        revert("OK");
    }
}
