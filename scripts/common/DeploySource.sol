// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../Constants.sol";

library DeploySource {
    function deploy(address asset, address proxyAdmin, address deployer, bytes32 salt)
        internal
        returns (
            SourceCore sourceCoreSingleton,
            TransparentUpgradeableProxy sourceCore,
            MellowOFTAdapter mellowOFTAdapter
        )
    {
        sourceCoreSingleton = new SourceCore();
        sourceCore = new TransparentUpgradeableProxy{salt: salt}(address(sourceCoreSingleton), proxyAdmin, "");
        mellowOFTAdapter = new MellowOFTAdapter{salt: salt}(asset, Constants.endpointV2(), deployer);
    }
}
