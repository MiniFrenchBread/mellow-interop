// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../interfaces/core/ITargetCoreStorage.sol";

contract TargetCoreStorage is ITargetCoreStorage, AccessControlEnumerableUpgradeable {
    /// @inheritdoc ITargetCoreStorage
    bytes32 public constant DEPOSIT_ROLE = keccak256("TARGET_CORE:DEPOSIT_ROLE");
    /// @inheritdoc ITargetCoreStorage
    bytes32 public constant REDEEM_ROLE = keccak256("TARGET_CORE:REDEEM_ROLE");
    /// @inheritdoc ITargetCoreStorage
    bytes32 public constant CLAIM_ROLE = keccak256("TARGET_CORE:CLAIM_ROLE");
    /// @inheritdoc ITargetCoreStorage
    bytes32 public constant PUSH_ROLE = keccak256("TARGET_CORE:PUSH_ROLE");

    /// @dev keccak256(abi.encode(uint256(keccak256(abi.encodePacked("mellow-interop.storage.TargetCore"))) - 1)) & ~bytes32(uint256(0xff));
    bytes32 private constant storageSlotRef = 0xa4b0e0c6727e33139d3521e8ca408d0b120de2c59eab4223b7ecace54ec3fa00;

    /// @inheritdoc ITargetCoreStorage
    function oft() public view returns (IMellowOFT) {
        return _targetStorage().oft;
    }

    /// @inheritdoc ITargetCoreStorage
    function vault() public view returns (IERC4626) {
        return _targetStorage().vault;
    }

    /// @inheritdoc ITargetCoreStorage
    function claimer() public view returns (address) {
        return _targetStorage().claimer;
    }

    /// @inheritdoc ITargetCoreStorage
    function sourceEndpointId() public view returns (uint32) {
        return _targetStorage().sourceEndpointId;
    }

    /// @inheritdoc ITargetCoreStorage
    function sourceCoreAddress() public view returns (bytes32) {
        return _targetStorage().sourceCoreAddress;
    }

    function __TargetCoreStorage_init(InitParams calldata params) internal onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, params.admin);

        if (params.admin == address(0) || params.vault == address(0) || params.claimer == address(0)) {
            revert("TargetCore: zero address");
        }
        if (params.sourceEndpointId == 0) {
            revert("TargetCore: zero value");
        }

        if (params.sourceCoreAddress == bytes32(0)) {
            revert("TargetCore: zero address");
        }

        TargetStorage storage $ = _targetStorage();
        $.vault = IERC4626(params.vault);
        $.oft = IMellowOFT($.vault.asset());
        $.claimer = params.claimer;
        $.sourceEndpointId = params.sourceEndpointId;
        $.sourceCoreAddress = params.sourceCoreAddress;

        if (params.depositRoleHolder != address(0)) {
            _grantRole(DEPOSIT_ROLE, params.depositRoleHolder);
        }

        if (params.redeemRoleHolder != address(0)) {
            _grantRole(REDEEM_ROLE, params.redeemRoleHolder);
        }

        if (params.claimRoleHolder != address(0)) {
            _grantRole(CLAIM_ROLE, params.claimRoleHolder);
        }

        if (params.pushRoleHolder != address(0)) {
            _grantRole(PUSH_ROLE, params.pushRoleHolder);
        }

        emit TargetCoreStorageInit(params);
    }

    function _targetStorage() private pure returns (TargetStorage storage $) {
        assembly {
            $.slot := storageSlotRef
        }
    }
}
