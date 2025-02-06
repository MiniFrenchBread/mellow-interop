// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../interfaces/IAdapter.sol";
import "../utils/OwnedERC20.sol";

abstract contract CoreStorage is Initializable {
    struct Storage {
        address asset;
        address adapter;
    }

    bytes32 private immutable coreStorageSlotRef;

    constructor(bytes32 name_, uint256 version_) {
        coreStorageSlotRef = keccak256(
            abi.encode(uint256(keccak256(abi.encodePacked("mellow-interop.storage.CoreStorage", name_, version_))) - 1)
        ) & ~bytes32(uint256(0xff));
    }

    function asset() public view returns (OwnedERC20) {
        return OwnedERC20(_coreStorage().asset);
    }

    function adapter() public view returns (IAdapter) {
        return IAdapter(_coreStorage().adapter);
    }

    function _setAsset(address asset_) internal onlyInitializing {
        _coreStorage().asset = asset_;
    }

    function _setAdapter(address adapter_) internal {
        _coreStorage().adapter = adapter_;
    }

    function _coreStorage() private view returns (Storage storage $) {
        bytes32 slot = coreStorageSlotRef;
        assembly {
            $.slot := slot
        }
    }
}
