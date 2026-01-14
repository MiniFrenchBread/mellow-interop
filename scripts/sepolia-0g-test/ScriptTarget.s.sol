// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../Constants.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    using OptionsBuilder for bytes;

    MellowOFT public mellowOFT = MellowOFT(0x4fed2B4d6c797f22026283a7a10A14B86Bd0636C);
    TargetCore public targetCore = TargetCore(0xD48b09Fc5fB2c3C8a24DD67e90542a8f443BA21b);

    function run() external {
        grantRoles(0x4786daAD7C694712AF390935C86f89e16b171C5f);
        // revert("ok" );
        return;
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        vm.startBroadcast(deployerPk);

        vm.stopBroadcast();
    }

    function updateLZConfig() internal {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        uint256 adminPk = uint256(bytes32(vm.envBytes("ADMIN_OG_TEST")));
        address deployer = vm.addr(deployerPk);
        address admin = vm.addr(adminPk);

        vm.startBroadcast(deployerPk);
        admin.call{value: 0.001 ether}("");
        vm.stopBroadcast();

        SetConfigParam[] memory params = new SetConfigParam[](1);
        UlnConfig memory config;
        config.confirmations = 20;
        uint32 sourceEid = Constants.endpointId(Constants.GALILEO_CHAINID);

        config.requiredDVNs = Constants.requiredDVNs(sourceEid);
        config.requiredDVNCount = uint8(config.requiredDVNs.length);
        params[0] = SetConfigParam({eid: sourceEid, configType: 2, config: abi.encode(config)});
        ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(mellowOFT.endpoint());

        vm.startBroadcast(adminPk);
        endpoint.setConfig(address(mellowOFT), Constants.sendLibrary(), params);
        endpoint.setConfig(address(mellowOFT), Constants.receiveLibrary(), params);
        vm.stopBroadcast();
    }

    function grantRoles(address grantee) internal {
        uint256 adminPk = uint256(bytes32(vm.envBytes("ADMIN_OG_TEST")));
        vm.startBroadcast(adminPk);
        targetCore.grantRole(targetCore.DEPOSIT_ROLE(), grantee);
        targetCore.grantRole(targetCore.REDEEM_ROLE(), grantee);
        targetCore.grantRole(targetCore.CLAIM_ROLE(), grantee);
        targetCore.grantRole(targetCore.PUSH_ROLE(), grantee);
        vm.stopBroadcast();
    }
}
