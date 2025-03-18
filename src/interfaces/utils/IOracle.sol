// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "@openzeppelin/contracts/access/IAccessControl.sol";

/**
 * @title IOracle
 * @dev Interface for the Oracle contract, responsible for providing and managing asset price data.
 *
 * The Oracle contract implements role-based access control for setting and modifying asset values,
 * ensuring only authorized addresses can update the price or adjust the maximum data age.
 */
interface IOracle {
    /**
     * @notice Role identifier for setting the asset value.
     */
    function SET_VALUE_ROLE() external view returns (bytes32);

    /**
     * @notice Role identifier for setting the maximum allowable data age.
     */
    function SET_MAX_AGE_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the address of the core contract with administrative control.
     */
    function core() external view returns (address);

    /**
     * @notice Returns the current stored value (asset price or data).
     */
    function value() external view returns (uint256);

    /**
     * @notice Returns the timestamp of the last update to the asset value.
     */
    function lastUpdated() external view returns (uint256);

    /**
     * @notice Returns the maximum allowed age (in seconds) before data is considered stale.
     */
    function maxAge() external view returns (uint256);

    /**
     * @notice Returns the current asset value if the data is valid and not stale.
     * @dev Reverts if the data is older than the `maxAge` threshold.
     */
    function getValue() external view returns (uint256);

    /**
     * @notice Updates the maximum allowable data age for the Oracle contract.
     * @dev Can only be called by an address with the `ORACLE:SET_MAX_AGE_ROLE`.
     * @param maxAge_ The new maximum age in seconds.
     */
    function setMaxAge(uint256 maxAge_) external;

    /**
     * @notice Updates the stored asset value.
     * @dev Can only be called by an address with the `ORACLE:SET_VALUE_ROLE`.
     * @param value_ The new asset value.
     */
    function setValue(uint256 value_) external;

    /**
     * @notice Emitted when the maximum data age is updated.
     * @param maxAge The new maximum age value in seconds.
     */
    event MaxAgeSet(uint256 indexed maxAge);

    /**
     * @notice Emitted when the asset value is updated.
     * @param value The new asset value.
     * @param timestamp The timestamp when the value was updated.
     */
    event ValueSet(uint256 indexed value, uint256 indexed timestamp);
}
