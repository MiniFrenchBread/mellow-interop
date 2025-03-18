// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../interfaces/utils/IOracle.sol";

contract Oracle is IOracle {
    /// @inheritdoc IOracle
    bytes32 public constant SET_VALUE_ROLE = keccak256("ORACLE:SET_VALUE_ROLE");
    /// @inheritdoc IOracle
    bytes32 public constant SET_MAX_AGE_ROLE = keccak256("ORACLE:SET_MAX_AGE_ROLE");

    /// @inheritdoc IOracle
    address public immutable core;
    /// @inheritdoc IOracle
    uint256 public value;
    /// @inheritdoc IOracle
    uint256 public lastUpdated;
    /// @inheritdoc IOracle
    uint256 public maxAge;

    constructor(address core_, uint256 initialValue_, uint256 initialMaxAge_) {
        core = core_;
        value = initialValue_;
        lastUpdated = block.timestamp;
        maxAge = initialMaxAge_;
    }

    modifier onlyRole(bytes32 role) {
        if (!IAccessControl(core).hasRole(role, msg.sender)) {
            revert("Oracle: forbidden");
        }
        _;
    }

    /// @inheritdoc IOracle
    function getValue() public view returns (uint256) {
        if (lastUpdated + maxAge < block.timestamp) {
            revert("Oracle: stale value");
        }
        return value;
    }

    /// @inheritdoc IOracle
    function setMaxAge(uint256 maxAge_) external onlyRole(SET_MAX_AGE_ROLE) {
        maxAge = maxAge_;
        emit MaxAgeSet(maxAge_);
    }

    /// @inheritdoc IOracle
    function setValue(uint256 value_) external onlyRole(SET_VALUE_ROLE) {
        value = value_;
        uint256 timestamp = block.timestamp;
        lastUpdated = timestamp;
        emit ValueSet(value_, timestamp);
    }
}
