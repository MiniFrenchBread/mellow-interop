// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/InitTarget.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("TEST_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);

        SourceCore sourceCore = SourceCore(0xeea0Ed9d5A71569fDA65b66C5983011e67C30F8f);
        TargetCore targetCore = TargetCore(0xeea0Ed9d5A71569fDA65b66C5983011e67C30F8f);
        MellowOFTAdapter mellowOFTAdapter = MellowOFTAdapter(0xBefE3a454df68688715A58E8842B0a697A3f0774);
        MellowOFT mellowOFT = MellowOFT(0x5D52954aa43536be08751048de51B44dF1833204);
        uint32 sourceEid = Constants.endpointId(Constants.OPTIMISM_CHAINID);

        vault.initialize(IERC20(mellowOFT), "Mellow OFT Vault", "MOFTV");
        InitTarget.init(
            targetCore,
            sourceEid,
            address(sourceCore),
            mellowOFT,
            address(mellowOFTAdapter),
            deployer,
            deployer,
            deployer,
            address(vault),
            address(vault)
        );

        vm.stopBroadcast();
        revert("OK");
    }
}

/*
    SourceCore singleton 0xcB536c7E2368970EEc0CBe46eBc5D79C7b72f4BD;
    SourceCore 0x0cFC89E03c52F1F091544De5848EBaFf21148DCc;
    MellowOFTAdapter 0xEF50Ef9Ea5B7Ae605DF63245cebCd01a94C81f90.
    TargetCore singleton 0x6f09a5a47E10a34460325350828151B397641efe;
    TargetCore 0x4afdf122Cc10AA017e65247DB7446a61c949628D;
    MellowOFT 0x6F678eb24036C5355600cf66ce316Cfb4BBD8B25.
*/
