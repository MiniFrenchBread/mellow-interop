// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../Constants.sol";

library InitTarget {
    using OptionsBuilder for bytes;

    function addressToBytes32(address addr_) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr_)));
    }

    struct InitParams {
        TargetCore targetCore;
        uint32 sourceEid;
        address sourceCoreAddress;
        MellowOFT mellowOFT;
        address mellowOFTAdapter;
        address deployer;
        address vaultAdmin;
        address vaultProxyAdmin;
        address curatorAdmin;
        address curatorOperator;
        address vault;
        address claimer;
    }

    function init(InitParams memory $) internal {
        $.targetCore.initialize(
            ITargetCoreStorage.InitParams({
                admin: $.vaultAdmin,
                vault: $.vault,
                claimer: $.claimer,
                sourceEndpointId: $.sourceEid,
                sourceCoreAddress: addressToBytes32($.sourceCoreAddress),
                depositRoleHolder: $.curatorOperator,
                redeemRoleHolder: $.curatorOperator,
                claimRoleHolder: $.curatorOperator,
                pushRoleHolder: $.curatorOperator
            })
        );
        {
            EnforcedOptionParam[] memory enforcedOptions = new EnforcedOptionParam[](1);
            enforcedOptions[0] = EnforcedOptionParam({
                eid: $.sourceEid,
                msgType: $.mellowOFT.SEND(),
                options: OptionsBuilder.newOptions().addExecutorLzReceiveOption(Constants.sendGas(), 0)
            });
            $.mellowOFT.setEnforcedOptions(enforcedOptions);
        }
        $.mellowOFT.setPeer($.sourceEid, addressToBytes32(address($.mellowOFTAdapter)));
        {
            SetConfigParam[] memory params = new SetConfigParam[](1);
            UlnConfig memory config;
            config.confirmations = 20;
            config.requiredDVNs = Constants.requiredDVNs($.sourceEid);
            config.requiredDVNCount = uint8(config.requiredDVNs.length);
            params[0] = SetConfigParam({eid: $.sourceEid, configType: 2, config: abi.encode(config)});
            ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2($.mellowOFT.endpoint());
            endpoint.setConfig(address($.mellowOFT), Constants.sendLibrary(), params);
            endpoint.setConfig(address($.mellowOFT), Constants.receiveLibrary(), params);
        }
        $.mellowOFT.setDelegate($.vaultAdmin);
        $.mellowOFT.transferOwnership($.vaultAdmin);
    }
}
