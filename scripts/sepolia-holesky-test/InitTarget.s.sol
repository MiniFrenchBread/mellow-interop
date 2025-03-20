// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/InitTarget.sol";
import "forge-std/Script.sol";

import {IMultiVault, MultiVault} from "@mellow-finance/simple-lrt/vaults/MultiVault.sol";

contract Deploy is Script {
    SourceCore sourceCore = SourceCore(0x0cFC89E03c52F1F091544De5848EBaFf21148DCc);
    TargetCore targetCore = TargetCore(0x4afdf122Cc10AA017e65247DB7446a61c949628D);
    MellowOFTAdapter mellowOFTAdapter = MellowOFTAdapter(0xEF50Ef9Ea5B7Ae605DF63245cebCd01a94C81f90);
    MellowOFT mellowOFT = MellowOFT(0x6F678eb24036C5355600cf66ce316Cfb4BBD8B25);
    uint32 sourceEid = Constants.endpointId(Constants.SEPOLIA_CHAINID);

    address multiVaultImplementation = 0x846357cEDe771733864203315Ae7E7F90aB9590B;
    address claimer = 0xc36A7e12311679898a326D2893003C48C3ACAcd5;
    address strategy = 0x33d02086eC87DdC57918Ff868f5eee4c27A739f3;

    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("TEST_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);

        bytes32 salt = bytes32(uint256(1));
        MultiVault vault = MultiVault(
            address(new TransparentUpgradeableProxy{salt: salt}(multiVaultImplementation, deployer, new bytes(0)))
        );

        vault.initialize(
            IMultiVault.InitParams({
                admin: deployer,
                limit: 100 ether,
                depositPause: false,
                withdrawalPause: false,
                depositWhitelist: false,
                asset: address(mellowOFT),
                name: "Mellow OFT MultiVault",
                symbol: "MOFTMV",
                depositStrategy: strategy,
                withdrawalStrategy: strategy,
                rebalanceStrategy: strategy,
                defaultCollateral: address(0),
                symbioticAdapter: address(0),
                eigenLayerAdapter: address(0),
                erc4626Adapter: address(0)
            })
        );
        console2.log("here");
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
            claimer
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
