// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "./Constants.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    using OptionsBuilder for bytes;

    // Test deployment
    address public immutable proxyAdmin = 0x5C0F3DE4ba6AD53bb8E27f965170A52671e525Bf;
    address public immutable admin = 0x5C0F3DE4ba6AD53bb8E27f965170A52671e525Bf;
    address public immutable operator = 0x5C0F3DE4ba6AD53bb8E27f965170A52671e525Bf;

    // SourceCore singleton 0x8f06BEB555D57F0D20dB817FF138671451084e24;
    // SourceCore 0xeea0Ed9d5A71569fDA65b66C5983011e67C30F8f;
    // MellowOFTAdapter 0xBefE3a454df68688715A58E8842B0a697A3f0774.
    // TargetCore singleton 0x8f06BEB555D57F0D20dB817FF138671451084e24;
    // TargetCore 0xeea0Ed9d5A71569fDA65b66C5983011e67C30F8f;
    // MellowOFT 0x5D52954aa43536be08751048de51B44dF1833204.

    SourceCore public sourceCore = SourceCore(0xeea0Ed9d5A71569fDA65b66C5983011e67C30F8f);
    MellowOFTAdapter public mellowOFTAdapter = MellowOFTAdapter(0xBefE3a454df68688715A58E8842B0a697A3f0774);
    MellowOFT public mellowOFT = MellowOFT(0x5D52954aa43536be08751048de51B44dF1833204);

    address public targetCoreAddress = 0xeea0Ed9d5A71569fDA65b66C5983011e67C30F8f;
    uint32 public targetEid = Constants.endpointId(Constants.ARBITRUM_CHAINID);

    function addressToBytes32(address addr_) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr_)));
    }

    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("TEST_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);

        sourceCore.initialize(
            ISourceCoreStorage.InitParams({
                admin: deployer,
                name: "MellowSourceCore",
                symbol: "MSC",
                mellowOFTAdapter: address(mellowOFTAdapter),
                epochDuration: 1 hours,
                targetEndpointId: targetEid,
                targetCoreAddress: addressToBytes32(targetCoreAddress),
                limit: 100 ether,
                oracleMaxAge: 2 hours,
                pushRoleHolder: operator,
                setWithdrawalDelayRoleHolder: deployer,
                setValueRoleHolder: deployer,
                setMaxAgeRoleHolder: deployer,
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
            mellowOFTAdapter.setPeer(targetEid, addressToBytes32(address(mellowOFT)));

            {
                address[] memory dvns = new address[](1);
                dvns[0] = Constants.layerZeroDVN();
                SetConfigParam[] memory params = new SetConfigParam[](1);
                params[0] = SetConfigParam({
                    eid: targetEid,
                    configType: 2,
                    config: abi.encode(
                        UlnConfig({
                            confirmations: 20,
                            requiredDVNCount: 1,
                            optionalDVNCount: 0,
                            optionalDVNThreshold: 0,
                            requiredDVNs: dvns,
                            optionalDVNs: new address[](0)
                        })
                    )
                });
                ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(mellowOFTAdapter.endpoint());
                endpoint.setConfig(address(mellowOFTAdapter), Constants.sendLibrary(), params);
            }

            mellowOFTAdapter.transferOwnership(address(admin));
        }

        IOracle oracle = sourceCore.oracle();
        oracle.setMaxAge(1 weeks);
        oracle.setValue(1 ether);

        IWithdrawalQueue withdrawalQueue = sourceCore.withdrawalQueue();
        withdrawalQueue.setWithdrawalDelay(1 weeks);

        sourceCore.grantRole(withdrawalQueue.SET_WITHDRAWAL_DELAY_ROLE(), admin);
        sourceCore.grantRole(oracle.SET_MAX_AGE_ROLE(), operator);
        sourceCore.grantRole(oracle.SET_VALUE_ROLE(), operator);
        sourceCore.grantRole(0x00, admin);

        if (operator != deployer && admin != deployer) {
            sourceCore.renounceRole(withdrawalQueue.SET_WITHDRAWAL_DELAY_ROLE(), deployer);
            sourceCore.renounceRole(oracle.SET_MAX_AGE_ROLE(), deployer);
            sourceCore.renounceRole(oracle.SET_VALUE_ROLE(), deployer);
            sourceCore.renounceRole(0x00, deployer);
        }
        vm.stopBroadcast();

        // revert("OK");
    }
}
