// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../utils/OwnedERC20.sol";
import "./IAdapter.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface ICoreStorage {
    struct Storage {
        address asset;
        address adapter;
    }

    function asset() external view returns (OwnedERC20);

    function adapter() external view returns (IAdapter);

    event AssetSet(address indexed asset);

    event AdapterSet(address indexed adapter);
}
