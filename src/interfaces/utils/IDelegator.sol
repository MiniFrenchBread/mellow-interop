// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import {
    ILayerZeroEndpointV2,
    Origin
} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title IDelegator
 * @dev Interface for the Delegator contract, which acts as a secure intermediary for executing cross-chain operations.
 *
 * The Delegator contract supports controlled calls to external contracts, ensuring role-based security and accountability.
 */
interface IDelegator {
    /**
     * @notice Role identifier for the operator role with elevated permissions.
     */
    function OPERATOR_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the LayerZero Endpoint V2 instance linked to this Delegator.
     */
    function endpointV2() external view returns (ILayerZeroEndpointV2);

    /**
     * @notice Executes a low-level call to an external contract with specified data and value transfer.
     * @dev Can only be called by an address with appropriate permissions.
     * @param target The address of the external contract to be called.
     * @param data The calldata payload to be executed.
     * @param value The amount of native currency (ETH) to send with the call.
     * @return response The response returned by the called contract.
     */
    function call(address target, bytes calldata data, uint256 value)
        external
        payable
        returns (bytes memory response);

    /**
     * @notice Clears a pending LayerZero operation by providing relevant data.
     * @dev This function is intended to manage failed or incomplete LayerZero transactions.
     * @param oapp_ The address of the OAPP (Omnichain Application) contract.
     * @param origin_ Origin data for the pending transaction.
     * @param guid_ The unique identifier of the transaction to clear.
     * @param message_ Additional message data related to the transaction.
     */
    function clear(address oapp_, Origin calldata origin_, bytes32 guid_, bytes calldata message_) external;

    /**
     * @notice Emitted when a successful call is executed.
     * @param target The address of the contract that was called.
     * @param data The calldata payload that was executed.
     * @param value The amount of ETH transferred with the call.
     * @param response The response data from the contract call.
     */
    event Call(address indexed target, bytes data, uint256 value, bytes response);

    /**
     * @notice Emitted when a pending LayerZero transaction is successfully cleared.
     * @param oapp The address of the OAPP contract related to the transaction.
     * @param origin The origin details of the cleared transaction.
     * @param guid The unique identifier of the cleared transaction.
     * @param message The message data provided for the cleared transaction.
     */
    event Clear(address indexed oapp, Origin origin, bytes32 guid, bytes message);
}
