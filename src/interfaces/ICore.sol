// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "./ICoreStorage.sol";
import "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

interface ICore is ICoreStorage {
    error InvalidMessageType();
    error Forbidden();
    error InvalidStatus();
    error LimitOverflow(uint256 targetValue, uint256 value);
    error LimitUnderflow(uint256 targetValue, uint256 value);

    function OPERATOR_ROLE() external view returns (bytes32);

    function setAdapter(address newAdapter) external;

    function receiveMessage(IAdapter.MessageType messageType, bytes calldata message) external payable;
}
