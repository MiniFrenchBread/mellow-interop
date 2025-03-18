// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "./Constants.sol";
import "forge-std/Script.sol";

contract MockVault is ERC4626Upgradeable {
    function initialize(IERC20 asset_, string memory name_, string memory symbol_) external initializer {
        __ERC4626_init(asset_);
        __ERC20_init(name_, symbol_);
    }

    function claim(bytes memory /* data */ ) public view returns (uint256) {
        return 0;
    }
}

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

    function addressToBytes32(address addr_) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr_)));
    }

    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("TEST_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);
        MockVault vault = new MockVault();
        vault.initialize(IERC20(mellowOFT), "MellowOFT Vault", "MOFTV");
        targetCore.initialize(
            ITargetCoreStorage.InitParams({
                admin: admin,
                vault: address(vault),
                claimer: address(vault),
                sourceEndpointId: sourceEid,
                sourceCoreAddress: addressToBytes32(address(sourceCore)),
                depositRoleHolder: operator,
                redeemRoleHolder: operator,
                claimRoleHolder: operator,
                pushRoleHolder: operator
            })
        );

        {
            EnforcedOptionParam[] memory enforcedOptions = new EnforcedOptionParam[](1);
            enforcedOptions[0] = EnforcedOptionParam({
                eid: targetEid,
                msgType: mellowOFT.SEND(),
                options: OptionsBuilder.newOptions().addExecutorLzReceiveOption(Constants.sendGas(), 0)
            });
            mellowOFT.setEnforcedOptions(enforcedOptions);
            mellowOFT.setPeer(sourceEid, addressToBytes32(address(mellowOFTAdapter)));

            {
                address[] memory dvns = new address[](1);
                dvns[0] = Constants.layerZeroDVN();
                SetConfigParam[] memory params = new SetConfigParam[](1);
                params[0] = SetConfigParam({
                    eid: sourceEid,
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
                ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(mellowOFT.endpoint());
                endpoint.setConfig(address(mellowOFT), Constants.sendLibrary(), params);
            }

            mellowOFT.transferOwnership(address(admin));
        }

        vm.stopBroadcast();

        // revert("OK");
    }
}
