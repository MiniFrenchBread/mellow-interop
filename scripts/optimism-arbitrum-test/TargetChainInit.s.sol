// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/InitTarget.sol";
import "forge-std/Script.sol";

contract MockVault is ERC4626Upgradeable {
    function initialize(IERC20 asset_, string memory name_, string memory symbol_) external initializer {
        __ERC4626_init(asset_);
        __ERC20_init(name_, symbol_);
    }

    function claim(bytes memory /* data */ ) public pure returns (uint256) {
        return 0;
    }
}

contract Deploy is Script {
    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("TEST_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);

        SourceCore sourceCore = SourceCore(0xeea0Ed9d5A71569fDA65b66C5983011e67C30F8f);
        TargetCore targetCore = TargetCore(0xeea0Ed9d5A71569fDA65b66C5983011e67C30F8f);
        MellowOFTAdapter mellowOFTAdapter = MellowOFTAdapter(0xBefE3a454df68688715A58E8842B0a697A3f0774);
        MellowOFT mellowOFT = MellowOFT(0x5D52954aa43536be08751048de51B44dF1833204);
        uint32 sourceEid = Constants.endpointId(Constants.OPTIMISM_CHAINID);

        MockVault vault = new MockVault();
        vault.initialize(IERC20(mellowOFT), "MellowOFT Vault", "MOFTV");
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
            address(vault)
        );

        vm.stopBroadcast();
        revert("OK");
    }
}
