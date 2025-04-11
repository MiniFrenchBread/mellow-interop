// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/InitSource.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("TEST_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);
        SourceCore sourceCore = SourceCore(0x0cFC89E03c52F1F091544De5848EBaFf21148DCc);
        address targetCoreAddress = 0x4afdf122Cc10AA017e65247DB7446a61c949628D;
        uint32 targetEid = Constants.endpointId(Constants.HOLESKY_CHAINID);
        MellowOFTAdapter mellowOFTAdapter = MellowOFTAdapter(0xEF50Ef9Ea5B7Ae605DF63245cebCd01a94C81f90);
        MellowOFT mellowOFT = MellowOFT(0x6F678eb24036C5355600cf66ce316Cfb4BBD8B25);

        InitSource.init(
            sourceCore,
            targetEid,
            targetCoreAddress,
            mellowOFTAdapter,
            mellowOFT,
            deployer,
            deployer,
            deployer,
            "Mellow Interop Sepolia-Holesky Test Vault",
            "MTV",
            1 hours,
            100 ether,
            1 weeks
        );

        vm.stopBroadcast();
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
