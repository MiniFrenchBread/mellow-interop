// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import {ISourceCore} from "../core/ISourceCore.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title IWithdrawalQueue
 * @dev Interface for the WithdrawalQueue contract that manages the delayed withdrawal process for SourceCore.
 *
 * This contract tracks user withdrawal requests, manages epoch-based processing, and ensures smooth redemption flow.
 */
interface IWithdrawalQueue {
    /**
     * @notice Role identifier for setting the withdrawal delay.
     */
    function SET_WITHDRAWAL_DELAY_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the SourceCore contract instance linked to this WithdrawalQueue.
     */
    function sourceCore() external view returns (ISourceCore);

    /**
     * @notice Returns the ERC20 token used as the primary asset in the system.
     */
    function asset() external view returns (IERC20);

    /**
     * @notice Returns the duration of each withdrawal epoch (in seconds).
     */
    function epochDuration() external view returns (uint256);

    /**
     * @notice Returns the timestamp when the contract was initialized.
     */
    function initTimestamp() external view returns (uint256);

    /**
     * @notice Returns the iterator tracking the current epoch.
     */
    function epochIterator() external view returns (uint256);

    /**
     * @notice Returns the current withdrawal delay in seconds.
     */
    function withdrawalDelay() external view returns (uint256);

    /**
     * @notice Returns the number of shares requested by an account for a given epoch.
     */
    function sharesOf(uint256 epoch, address account) external view returns (uint256);

    /**
     * @notice Returns the total amount of assets withdrawn for a specific epoch.
     */
    function withdrawals(uint256 epoch) external view returns (uint256);

    /**
     * @notice Returns the total shares requested for withdrawal in a given epoch.
     */
    function shares(uint256 epoch) external view returns (uint256);

    /**
     * @notice Returns the total number of shares currently in the WithdrawalQueue.
     */
    function totalShares() external view returns (uint256);

    /**
     * @notice Updates the withdrawal delay for the contract.
     * @param withdrawalDelay_ New withdrawal delay in seconds.
     */
    function setWithdrawalDelay(uint256 withdrawalDelay_) external;

    /**
     * @notice Registers a withdrawal request for the specified account and amount.
     * @param account The address of the account requesting the withdrawal.
     * @param shares_ The number of shares requested for withdrawal.
     */
    function request(address account, uint256 shares_) external;

    /**
     * @notice Claims assets previously requested for withdrawal for a given epoch.
     * @param epoch The epoch during which the withdrawal was requested.
     * @param receiver The address to which the claimed assets will be sent.
     * @return assets The number of assets claimed.
     */
    function claim(uint256 epoch, address receiver) external returns (uint256 assets);

    /**
     * @notice Handles epoch advancement and ensures pending withdrawals are processed accordingly.
     */
    function handleEpoch() external;

    /**
     * @notice Returns the current epoch based on the contract's initialization timestamp and epoch duration.
     */
    function currentEpoch() external view returns (uint256);

    /**
     * @notice Emitted when a withdrawal request is registered.
     * @param epoch The epoch during which the request was made.
     * @param account The address of the account that made the request.
     * @param shares The number of shares requested for withdrawal.
     */
    event Request(uint256 indexed epoch, address indexed account, uint256 indexed shares);

    /**
     * @notice Emitted when assets are successfully claimed after a withdrawal request.
     * @param epoch The epoch during which the claim was processed.
     * @param account The address of the account that claimed the assets.
     * @param assets The number of claimed assets.
     */
    event Claim(uint256 indexed epoch, address indexed account, uint256 indexed assets);

    /**
     * @notice Emitted when the contract processes an epoch and finalizes pending withdrawals.
     * @param epoch The epoch that was processed.
     * @param shares The total number of shares processed.
     * @param assets The total number of assets distributed.
     */
    event HandleEpoch(uint256 indexed epoch, uint256 indexed shares, uint256 indexed assets);

    /**
     * @notice Emitted when the withdrawal delay is updated.
     * @param withdrawalDelay_ The new withdrawal delay in seconds.
     */
    event WithdrawalDelaySet(uint256 indexed withdrawalDelay_);
}
