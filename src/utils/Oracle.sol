// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "@openzeppelin/contracts/access/IAccessControl.sol";

contract Oracle {
    error Forbidden();

    bytes32 public constant SET_VALUE_ROLE = keccak256("ORACLE:SET_VALUE_ROLE");
    bytes32 public constant SET_MAX_AGE_ROLE = keccak256("ORACLE:SET_MAX_AGE_ROLE");

    address public immutable core;

    uint256 public value;
    uint256 public lastUpdated;
    uint256 public maxAge;

    constructor(address core_) {
        core = core_;
    }

    modifier onlyRole(bytes32 role) {
        if (!IAccessControl(core).hasRole(role, msg.sender)) {
            revert Forbidden();
        }
        _;
    }

    function getValue() public view returns (uint256) {
        if (lastUpdated + maxAge < block.timestamp) {
            revert Forbidden();
        }
        return value;
    }

    function setMaxAge(uint256 maxAge_) external onlyRole(SET_MAX_AGE_ROLE) {
        maxAge = maxAge_;
        // event
    }

    function setValue(uint256 value_) external onlyRole(SET_VALUE_ROLE) {
        value = value_;
        lastUpdated = block.timestamp;
        // event
    }
}
