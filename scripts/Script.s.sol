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
    TargetCore public targetCore = TargetCore(0xeea0Ed9d5A71569fDA65b66C5983011e67C30F8f);
    MellowOFTAdapter public mellowOFTAdapter = MellowOFTAdapter(0xBefE3a454df68688715A58E8842B0a697A3f0774);
    MellowOFT public mellowOFT = MellowOFT(0x5D52954aa43536be08751048de51B44dF1833204);

    uint32 public targetEid = Constants.endpointId(Constants.ARBITRUM_CHAINID);
    uint32 public sourceEid = Constants.endpointId(Constants.OPTIMISM_CHAINID);

    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("TEST_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);

        {
            // address[] memory dvns = new address[](2);
            // dvns[0] = 0x2f55c492897526677c5b68fb199ea31e2c126416;
            // dvns[1] = 0xd56e4eab23cb81f43168f9f45211eb027b9ac7cc;
            SetConfigParam[] memory params = new SetConfigParam[](1);
            params[0] = SetConfigParam({
                eid: targetEid,
                configType: 2,
                config: abi.encode(
                    UlnConfig({
                        confirmations: 20,
                        requiredDVNCount: 0,
                        optionalDVNCount: 0,
                        optionalDVNThreshold: 0,
                        requiredDVNs: new address[](0),
                        optionalDVNs: new address[](0)
                    })
                )
            });
            ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(mellowOFT.endpoint());
            endpoint.setConfig(address(mellowOFT), Constants.sendLibrary(), params);
            endpoint.setConfig(address(mellowOFT), Constants.receiveLibrary(), params);
            endpoint.setConfig(_oapp, _lib, _params);
        }

        IERC20 asset = IERC20(sourceCore.asset());
        uint256 balance = 0.0001 ether;
        // asset.approve(address(sourceCore), type(uint256).max);
        sourceCore.deposit(balance, deployer);
        sourceCore.pushToTarget{value: 0.001 ether}();

        vm.stopBroadcast();

        // revert("OK");
    }
}
