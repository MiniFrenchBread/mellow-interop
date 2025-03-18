// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "./Constants.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    using OptionsBuilder for bytes;

    // // Test deployment
    // address public immutable proxyAdmin = 0x5C0F3DE4ba6AD53bb8E27f965170A52671e525Bf;
    // address public immutable admin = 0x5C0F3DE4ba6AD53bb8E27f965170A52671e525Bf;
    // address public immutable operator = 0x5C0F3DE4ba6AD53bb8E27f965170A52671e525Bf;

    // SourceCore public sourceCore = SourceCore(address(2));
    // MellowOFTAdapter public mellowOFTAdapter = MellowOFTAdapter(address(3));
    // MellowOFT public mellowOFT = MellowOFT(address(3));

    // address public immutable targetOFT = address(4);
    // address public immutable targetCoreAddress = address(5);
    // uint32 public immutable targetEid = uint32(6);

    // function addressToBytes32(address addr_) internal pure returns (bytes32) {
    //     return bytes32(uint256(uint160(addr_)));
    // }

    // function run() external {
    //     uint256 deployerPk = uint256(bytes32(vm.envBytes("TEST_DEPLOYER")));
    //     address deployer = vm.addr(deployerPk);

    //     vm.startBroadcast(deployerPk);

    //     sourceCore.initialize(
    //         ISourceCoreStorage.InitParams({
    //             admin: deployer,
    //             name: "MellowSourceCore",
    //             symbol: "MSC",
    //             mellowOFTAdapter: address(mellowOFTAdapter),
    //             epochDuration: 1 hours,
    //             targetEndpointId: targetEid,
    //             targetCoreAddress: addressToBytes32(targetCoreAddress),
    //             limit: 100 ether,
    //             pushRoleHolder: operator,
    //             setWithdrawalDelayRoleHolder: deployer,
    //             setValueRoleHolder: deployer,
    //             setMaxAgeRoleHolder: deployer,
    //             setLimitRoleHolder: operator
    //         })
    //     );

    //     {
    //         EnforcedOptionParam[] memory enforcedOptions = new EnforcedOptionParam[](1);
    //         enforcedOptions[0] = EnforcedOptionParam({
    //             eid: targetEid,
    //             msgType: mellowOFTAdapter.SEND(),
    //             options: OptionsBuilder.newOptions().addExecutorLzReceiveOption(Constants.sendGas(), 0)
    //         });
    //         mellowOFTAdapter.setEnforcedOptions(enforcedOptions);
    //         mellowOFTAdapter.setPeer(targetEid, addressToBytes32(address(mellowOFT)));

    //         {
    //             address[] memory dvns = new address[](1);
    //             dvns[0] = Constants.layerZeroDVN();
    //             SetConfigParam[] memory params = new SetConfigParam[](1);
    //             params[0] = SetConfigParam({
    //                 eid: targetEid,
    //                 configType: 2,
    //                 config: abi.encode(
    //                     UlnConfig({
    //                         confirmations: 10,
    //                         requiredDVNCount: 1,
    //                         optionalDVNCount: 1,
    //                         optionalDVNThreshold: 1,
    //                         requiredDVNs: dvns,
    //                         optionalDVNs: new address[](0)
    //                     })
    //                 )
    //             });
    //             ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(mellowOFTAdapter.endpoint());
    //             endpoint.setConfig(address(mellowOFTAdapter), Constants.sendLibrary(), params);
    //         }

    //         mellowOFTAdapter.transferOwnership(address(admin));
    //     }

    //     IOracle oracle = sourceCore.oracle();
    //     oracle.setMaxAge(1 weeks);
    //     oracle.setValue(1 ether);

    //     IWithdrawalQueue withdrawalQueue = sourceCore.withdrawalQueue();
    //     withdrawalQueue.setWithdrawalDelay(1 weeks);

    //     sourceCore.grantRole(withdrawalQueue.SET_WITHDRAWAL_DELAY_ROLE(), admin);
    //     sourceCore.grantRole(oracle.SET_MAX_AGE_ROLE(), operator);
    //     sourceCore.grantRole(oracle.SET_VALUE_ROLE(), operator);
    //     sourceCore.grantRole(0x00, admin);

    //     sourceCore.renounceRole(withdrawalQueue.SET_WITHDRAWAL_DELAY_ROLE(), deployer);
    //     sourceCore.renounceRole(oracle.SET_MAX_AGE_ROLE(), deployer);
    //     sourceCore.renounceRole(oracle.SET_VALUE_ROLE(), deployer);
    //     sourceCore.renounceRole(0x00, deployer);

    //     vm.stopBroadcast();

    //     revert("OK");
    // }
}
