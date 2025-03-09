// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IOracle {
    function SET_VALUE_ROLE() external view returns (bytes32);

    function SET_MAX_AGE_ROLE() external view returns (bytes32);

    function core() external view returns (address);

    function value() external view returns (uint256);

    function lastUpdated() external view returns (uint256);

    function maxAge() external view returns (uint256);

    function getValue() external view returns (uint256);

    function setMaxAge(uint256 maxAge_) external;

    function setValue(uint256 value_) external;

    event MaxAgeSet(uint256 indexed maxAge);

    event ValueSet(uint256 indexed value, uint256 indexed timestamp);
}
