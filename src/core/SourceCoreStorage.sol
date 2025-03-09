// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import "../interfaces/core/ISourceCoreStorage.sol";
import {Oracle} from "../utils/Oracle.sol";
import {WithdrawalQueue} from "../utils/WithdrawalQueue.sol";

contract SourceCoreStorage is
    ISourceCoreStorage,
    ERC4626Upgradeable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /// @inheritdoc ISourceCoreStorage
    bytes32 public constant PUSH_ROLE = keccak256("SOURCE_CORE:PUSH_ROLE");

    /// @dev keccak256(abi.encode(uint256(keccak256(abi.encodePacked("mellow-interop.storage.SourceCore"))) - 1)) & ~bytes32(uint256(0xff));
    bytes32 private constant storageSlotRef = 0xeb30039081bb57aacc4645369147b1654132a2ddcd85d2f761c6128c51fded00;

    /// @inheritdoc ISourceCoreStorage
    function withdrawalQueue() public view returns (IWithdrawalQueue) {
        return _sourceStorage().withdrawalQueue;
    }

    /// @inheritdoc ISourceCoreStorage
    function oftAdapter() public view returns (IMellowOFTAdapter) {
        return _sourceStorage().oftAdapter;
    }

    /// @inheritdoc ISourceCoreStorage
    function oracle() public view returns (IOracle) {
        return _sourceStorage().oracle;
    }

    /// @inheritdoc ISourceCoreStorage
    function targetEndpointId() public view returns (uint32) {
        return _sourceStorage().targetEndpointId;
    }

    /// @inheritdoc ISourceCoreStorage
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

        address asset = IMellowOFTAdapter(params.mellowOFTAdapter).token();
        __ERC20_init(params.name, params.symbol);
        __ERC4626_init(IERC20(asset));

        _grantRole(DEFAULT_ADMIN_ROLE, params.admin);

        SourceStorage storage $ = _sourceStorage();

        $.withdrawalQueue = IWithdrawalQueue(address(new WithdrawalQueue(params.epochDuration, asset)));
        $.oftAdapter = IMellowOFTAdapter(params.mellowOFTAdapter);
        $.oftAdapter.initialize(address(this));
        $.oracle = IOracle(address(new Oracle(address(this))));

        $.targetEndpointId = params.targetEndpointId;
        $.targetCoreAddress = params.targetCoreAddress;

        if (params.pushRoleHolder != address(0)) {
            _grantRole(PUSH_ROLE, params.pushRoleHolder);
        }

        if (params.setWithdrawalDelayRoleHolder != address(0)) {
            _grantRole(withdrawalQueue().SET_WITHDRAWAL_DELAY_ROLE(), params.setWithdrawalDelayRoleHolder);
        }

        if (params.setValueRoleHolder != address(0)) {
            _grantRole(oracle().SET_VALUE_ROLE(), params.setValueRoleHolder);
        }

        if (params.setMaxAgeRoleHolder != address(0)) {
            _grantRole(oracle().SET_MAX_AGE_ROLE(), params.setMaxAgeRoleHolder);
        }

        emit SourceCoreStorageInitialized(params, $.withdrawalQueue, $.oracle);
    }

    function _sourceStorage() private pure returns (SourceStorage storage $) {
        assembly {
            $.slot := storageSlotRef
        }
    }
}
