// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../Constants.sol";

library InitSource {
    using OptionsBuilder for bytes;

    function addressToBytes32(address addr_) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr_)));
    }

    function init(
        SourceCore sourceCore,
        uint32 targetEid,
        address targetCoreAddress,
        MellowOFTAdapter mellowOFTAdapter,
        MellowOFT mellowOFT,
        address deployer,
        address admin,
        address operator,
        string memory name,
        string memory symbol,
        uint256 epochDuration,
        uint256 limit,
        uint256 oracleMaxAge
    ) internal {
        sourceCore.initialize(
            ISourceCoreStorage.InitParams({
                admin: deployer,
                name: name,
                symbol: symbol,
                mellowOFTAdapter: address(mellowOFTAdapter),
                epochDuration: epochDuration,
                targetEndpointId: targetEid,
                targetCoreAddress: addressToBytes32(targetCoreAddress),
                limit: limit,
                oracleMaxAge: oracleMaxAge,
                pushRoleHolder: operator,
                setWithdrawalDelayRoleHolder: deployer,
                setValueRoleHolder: operator,
                setMaxAgeRoleHolder: operator,
                setLimitRoleHolder: operator
            })
        );
        {
            EnforcedOptionParam[] memory enforcedOptions = new EnforcedOptionParam[](1);
            enforcedOptions[0] = EnforcedOptionParam({
                eid: targetEid,
                msgType: mellowOFTAdapter.SEND(),
                options: OptionsBuilder.newOptions().addExecutorLzReceiveOption(Constants.sendGas(), 0)
            });
            mellowOFTAdapter.setEnforcedOptions(enforcedOptions);
        }
        mellowOFTAdapter.setPeer(targetEid, addressToBytes32(address(mellowOFT)));

        SetConfigParam[] memory params = new SetConfigParam[](1);
        UlnConfig memory config;
        config.confirmations = 20;
        params[0] = SetConfigParam({eid: targetEid, configType: 2, config: abi.encode(config)});
        {
            ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(mellowOFTAdapter.endpoint());
            endpoint.setConfig(address(mellowOFTAdapter), Constants.sendLibrary(), params);
            endpoint.setConfig(address(mellowOFTAdapter), Constants.receiveLibrary(), params);
        }
        if (deployer != admin) {
            mellowOFTAdapter.transferOwnership(address(admin));
        }

        IWithdrawalQueue withdrawalQueue = sourceCore.withdrawalQueue();
        withdrawalQueue.setWithdrawalDelay(1 weeks);
        if (admin != deployer) {
            sourceCore.grantRole(withdrawalQueue.SET_WITHDRAWAL_DELAY_ROLE(), admin);
            sourceCore.grantRole(0x00, admin);
            sourceCore.renounceRole(withdrawalQueue.SET_WITHDRAWAL_DELAY_ROLE(), deployer);
            sourceCore.renounceRole(0x00, deployer);
        }
    }
}
