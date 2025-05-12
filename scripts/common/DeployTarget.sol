// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../Constants.sol";

library DeployTarget {
    function deploy(address proxyAdmin, address deployer, bytes32 salt, string memory name, string memory symbol)
        internal
        returns (TargetCore targetCoreSigleton, TransparentUpgradeableProxy targetCore, MellowOFT mellowOFT)
    {
        targetCoreSigleton = new TargetCore();
        targetCore = new TransparentUpgradeableProxy{salt: salt}(address(targetCoreSigleton), proxyAdmin, "");
        mellowOFT = new MellowOFT{salt: salt}(name, symbol, Constants.endpointV2(), deployer);
    }

    function deploy(
        TargetCore targetCoreSigleton,
        address proxyAdmin,
        address deployer,
        bytes32 salt,
        string memory name,
        string memory symbol
    ) internal returns (TransparentUpgradeableProxy targetCore, MellowOFT mellowOFT) {
        targetCore = new TransparentUpgradeableProxy{salt: salt}(address(targetCoreSigleton), proxyAdmin, "");
        mellowOFT = new MellowOFT{salt: salt}(name, symbol, Constants.endpointV2(), deployer);
    }
}
