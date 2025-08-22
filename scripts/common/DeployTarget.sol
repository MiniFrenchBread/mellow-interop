// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../Constants.sol";

library DeployTarget {
    function deploy(address proxyAdmin, address deployer, bytes32 salt, string memory name, string memory symbol)
        internal
        returns (TargetCore targetCoreSingleton, TransparentUpgradeableProxy targetCore, MellowOFT mellowOFT)
    {
        targetCoreSingleton = new TargetCore();
        targetCore = new TransparentUpgradeableProxy{salt: salt}(address(targetCoreSingleton), proxyAdmin, "");
        mellowOFT = new MellowOFT{salt: salt}(name, symbol, Constants.endpointV2(), deployer);
    }

    function deploy(
        TargetCore targetCoreSingleton,
        address proxyAdmin,
        address deployer,
        bytes32 salt,
        string memory name,
        string memory symbol
    ) internal returns (TransparentUpgradeableProxy targetCore, MellowOFT mellowOFT) {
        targetCore = new TransparentUpgradeableProxy{salt: salt}(address(targetCoreSingleton), proxyAdmin, "");
        mellowOFT = new MellowOFT{salt: salt}(name, symbol, Constants.endpointV2(), deployer);
    }
}
