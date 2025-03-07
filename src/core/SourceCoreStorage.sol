// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {MellowOFTAdapter} from "../oft/MellowOFTAdapter.sol";
import {Oracle} from "../utils/Oracle.sol";
import {WithdrawalQueue} from "../utils/WithdrawalQueue.sol";
import {AccessControlEnumerableUpgradeable} from
    "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import {ERC4626Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract SourceCoreStorage is
    ERC4626Upgradeable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable
{
    bytes32 public constant PUSH_ROLE = keccak256("SOURCE_CORE:PUSH_ROLE");

    /// @dev keccak256(abi.encode(uint256(keccak256(abi.encodePacked("mellow-interop.storage.SourceCore"))) - 1)) & ~bytes32(uint256(0xff));
    bytes32 private constant storageSlotRef = 0xeb30039081bb57aacc4645369147b1654132a2ddcd85d2f761c6128c51fded00;

    struct InitParams {
        string name;
        string symbol;
        address admin;
        address mellowOFTAdapter;
        uint256 epochDuration;
        uint32 targetEndpointId;
        bytes32 targetCoreAddress;
        address pushRoleHolder;
        address setWithdrawalDelayRoleHoler;
        address setValueRoleHoler;
        address setMaxAgeRoleHoler;
    }

    struct SourceStorage {
        WithdrawalQueue withdrawalQueue;
        MellowOFTAdapter oftAdapter;
        Oracle oracle;
        uint32 targetEndpointId;
        bytes32 targetCoreAddress;
    }

    function withdrawalQueue() public view returns (WithdrawalQueue) {
        return _sourceStorage().withdrawalQueue;
    }

    function oftAdapter() public view returns (MellowOFTAdapter) {
        return _sourceStorage().oftAdapter;
    }

    function oracle() public view returns (Oracle) {
        return _sourceStorage().oracle;
    }

    function targetEndpointId() public view returns (uint32) {
        return _sourceStorage().targetEndpointId;
    }

    function targetCoreAddress() public view returns (bytes32) {
        return _sourceStorage().targetCoreAddress;
    }

    function __SourceCoreStorage_init(InitParams calldata params) internal onlyInitializing {
        if (params.admin == address(0) || params.mellowOFTAdapter == address(0)) {
            revert("SourceCoreStorage: zero address");
        }

        if (params.epochDuration == 0 || params.targetEndpointId == 0 || params.targetCoreAddress == bytes32(0)) {
            revert("SourceCoreStorage: zero value");
        }

        address asset = MellowOFTAdapter(params.mellowOFTAdapter).token();
        __ERC20_init(params.name, params.symbol);
        __ERC4626_init(IERC20(asset));

        _grantRole(DEFAULT_ADMIN_ROLE, params.admin);

        SourceStorage storage $ = _sourceStorage();

        $.withdrawalQueue = new WithdrawalQueue(params.epochDuration, asset);
        $.oftAdapter = MellowOFTAdapter(params.mellowOFTAdapter);
        $.oftAdapter.initialize(address(this));
        $.oracle = new Oracle(address(this));

        $.targetEndpointId = params.targetEndpointId;
        $.targetCoreAddress = params.targetCoreAddress;

        if (params.pushRoleHolder != address(0)) {
            _grantRole(PUSH_ROLE, params.pushRoleHolder);
        }

        if (params.setWithdrawalDelayRoleHoler != address(0)) {
            _grantRole(withdrawalQueue().SET_WITHDRAWAL_DELAY_ROLE(), params.setWithdrawalDelayRoleHoler);
        }

        if (params.setValueRoleHoler != address(0)) {
            _grantRole(oracle().SET_VALUE_ROLE(), params.setValueRoleHoler);
        }

        if (params.setMaxAgeRoleHoler != address(0)) {
            _grantRole(oracle().SET_MAX_AGE_ROLE(), params.setMaxAgeRoleHoler);
        }
    }

    function _sourceStorage() private pure returns (SourceStorage storage $) {
        assembly {
            $.slot := storageSlotRef
        }
    }
}
