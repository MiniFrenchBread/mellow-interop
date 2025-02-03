// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../utils/OwnedERC20.sol";
import "./IAdapter.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

interface ICore {
    function asset() external view returns (OwnedERC20);

    function adapter() external view returns (IAdapter);

    function setAdapter(address newAdapter) external;

    function receiveMessage(IAdapter.MessageType messageType, bytes calldata message) external payable;
}
