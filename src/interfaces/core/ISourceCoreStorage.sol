// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {IMellowOFTAdapter} from "../oft/IMellowOFTAdapter.sol";
import {IOracle} from "../utils/IOracle.sol";
import {IWithdrawalQueue} from "../utils/IWithdrawalQueue.sol";
import {
    AccessControlEnumerableUpgradeable,
    IAccessControlEnumerable
} from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import {
    ERC4626Upgradeable,
    IERC4626
} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ISourceCoreStorage
 * @dev Interface that defines the core storage layout for the SourceCore contract.
 *
 * This interface defines key storage variables, initialization parameters, and role-based access logic.
 */
interface ISourceCoreStorage is IERC4626, IAccessControlEnumerable {
    /**
     * @notice Structure containing initialization parameters for SourceCore.
     * @param admin Admin address with primary control over key functions, assigned to the `DEFAULT_ADMIN_ROLE`.
     * @param name Name of the ERC20 token representing deposited shares.
     * @param symbol Symbol for the ERC20 token representing deposited shares.
     * @param mellowOFTAdapter Address of the MellowOFTAdapter contract.
     * @param epochDuration Duration of each withdrawal epoch.
     * @param targetEndpointId Identifier for the target endpoint in LayerZero.
     * @param targetCoreAddress Address of the target core contract.
     * @param limit Maximum number of assets allowed in the contract.
     * @param oracleMaxAge Initial value for maximum duration before oracle data is considered stale.
     * @param pushRoleHolder Address assigned to the `SOURCE_CORE:PUSH_ROLE`.
     * @param setWithdrawalDelayRoleHolder Address assigned to the `WITHDRAWAL_QUEUE:SET_WITHDRAWAL_DELAY_ROLE`.
     * @param setValueRoleHolder Address assigned to the `ORACLE:SET_VALUE_ROLE`.
     * @param setMaxAgeRoleHolder Address assigned to the `ORACLE:SET_MAX_AGE_ROLE`.
     * @param setLimitRoleHolder Address assigned to the `SOURCE_CORE:SET_LIMIT_ROLE`.
     */
    struct InitParams {
        address admin;
        string name;
        string symbol;
        address mellowOFTAdapter;
        uint256 epochDuration;
        uint32 targetEndpointId;
        bytes32 targetCoreAddress;
        uint256 limit;
        uint256 oracleMaxAge;
        address pushRoleHolder;
        address setWithdrawalDelayRoleHolder;
        address setValueRoleHolder;
        address setMaxAgeRoleHolder;
        address setLimitRoleHolder;
    }

    /**
     * @notice Structure containing core SourceCore storage references.
     * @param withdrawalQueue Instance of the WithdrawalQueue contract.
     * @param oftAdapter Instance of the MellowOFTAdapter contract.
     * @param oracle Instance of the Oracle contract.
     * @param targetEndpointId Identifier for the target endpoint in LayerZero.
     * @param targetCoreAddress Address of the target core contract.
     * @param limit Maximum number of assets allowed in the contract.
     */
    struct SourceStorage {
        IWithdrawalQueue withdrawalQueue;
        IMellowOFTAdapter oftAdapter;
        IOracle oracle;
        uint32 targetEndpointId;
        bytes32 targetCoreAddress;
        uint256 limit;
    }

    /**
     * @notice Returns the precision factor for 18 decimal places (1 ether).
     */
    function D18() external view returns (uint256);

    /**
     * @notice Returns the `PUSH_ROLE` identifier for authorized push operations.
     */
    function PUSH_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the `SET_LIMIT_ROLE` identifier for authorized asset limit adjustments.
     */
    function SET_LIMIT_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the WithdrawalQueue contract instance.
     */
    function withdrawalQueue() external view returns (IWithdrawalQueue);

    /**
     * @notice Returns the MellowOFTAdapter contract instance.
     */
    function oftAdapter() external view returns (IMellowOFTAdapter);

    /**
     * @notice Returns the Oracle contract instance for asset valuation.
     */
    function oracle() external view returns (IOracle);

    /**
     * @notice Returns the target endpoint identifier in LayerZero.
     */
    function targetEndpointId() external view returns (uint32);

    /**
     * @notice Returns the address of the target core contract.
     */
    function targetCoreAddress() external view returns (bytes32);

    /**
     * @notice Returns the current asset limit set in the contract.
     */
    function limit() external view returns (uint256);

    /**
     * @notice Sets a new asset limit for the contract.
     * @param limit New asset limit value.
     */
    function setLimit(uint256 limit) external;

    /**
     * @notice Emitted when the asset limit is updated.
     * @param limit The new asset limit value.
     */
    event LimitSet(uint256 limit);

    /**
     * @notice Emitted when the SourceCore storage is initialized.
     * @param params The initialization parameters.
     * @param withdrawalQueue The linked WithdrawalQueue contract instance.
     * @param oracle The linked Oracle contract instance.
     */
    event SourceCoreStorageInitialized(InitParams params, IWithdrawalQueue withdrawalQueue, IOracle oracle);
}
