// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../Constants.sol";

library InitSource {
    using OptionsBuilder for bytes;

    function addressToBytes32(address addr_) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr_)));
    }

    struct InitParams {
        address deployer;
        address vaultAdmin;
        address vaultProxyAdmin;
        address oracleUpdater;
        address curatorAdmin;
        address curatorOperator;
        SourceCore sourceCore;
        uint32 targetEid;
        address targetCoreAddress;
        MellowOFTAdapter mellowOFTAdapter;
        MellowOFT mellowOFT;
        string name;
        string symbol;
        uint256 epochDuration;
        uint256 limit;
        uint256 oracleMaxAge;
        uint256 withdrawalDelay;
    }

    function init(InitParams memory $) internal {
        $.sourceCore.initialize(
            ISourceCoreStorage.InitParams({
                admin: $.deployer,
                name: $.name,
                symbol: $.symbol,
                mellowOFTAdapter: address($.mellowOFTAdapter),
                epochDuration: $.epochDuration,
                targetEndpointId: $.targetEid,
                targetCoreAddress: addressToBytes32($.targetCoreAddress),
                limit: $.limit,
                oracleMaxAge: $.oracleMaxAge,
                pushRoleHolder: $.curatorOperator,
                setWithdrawalDelayRoleHolder: $.deployer,
                setValueRoleHolder: $.oracleUpdater,
                setMaxAgeRoleHolder: $.vaultAdmin,
                setLimitRoleHolder: $.curatorAdmin
            })
        );
        {
            EnforcedOptionParam[] memory enforcedOptions = new EnforcedOptionParam[](1);
            enforcedOptions[0] = EnforcedOptionParam({
                eid: $.targetEid,
                msgType: $.mellowOFTAdapter.SEND(),
                options: OptionsBuilder.newOptions().addExecutorLzReceiveOption(Constants.sendGas(), 0)
            });
            $.mellowOFTAdapter.setEnforcedOptions(enforcedOptions);
        }
        $.mellowOFTAdapter.setPeer($.targetEid, addressToBytes32(address($.mellowOFT)));
        {
            SetConfigParam[] memory params = new SetConfigParam[](1);
            UlnConfig memory config;
            config.confirmations = 20;
            config.requiredDVNs = Constants.requiredDVNs(Constants.endpointId(block.chainid));
            config.requiredDVNCount = uint8(config.requiredDVNs.length);
            params[0] = SetConfigParam({eid: $.targetEid, configType: 2, config: abi.encode(config)});
            ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2($.mellowOFTAdapter.endpoint());
            endpoint.setConfig(address($.mellowOFTAdapter), Constants.sendLibrary(), params);
            endpoint.setConfig(address($.mellowOFTAdapter), Constants.receiveLibrary(), params);
        }
        $.mellowOFTAdapter.setDelegate($.vaultAdmin);
        $.mellowOFTAdapter.transferOwnership($.vaultAdmin);

        IWithdrawalQueue withdrawalQueue = $.sourceCore.withdrawalQueue();
        withdrawalQueue.setWithdrawalDelay($.withdrawalDelay);
        $.sourceCore.grantRole(withdrawalQueue.SET_WITHDRAWAL_DELAY_ROLE(), $.vaultAdmin);
        $.sourceCore.grantRole(0x00, $.vaultAdmin);
        $.sourceCore.renounceRole(withdrawalQueue.SET_WITHDRAWAL_DELAY_ROLE(), $.deployer);
        $.sourceCore.renounceRole(0x00, $.deployer);
    }
}
