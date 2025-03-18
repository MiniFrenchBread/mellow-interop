// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {IMellowOFTAdapter} from "../oft/IMellowOFTAdapter.sol";
import {ISourceCoreStorage} from "./ISourceCoreStorage.sol";
import {
    MessagingFee, MessagingReceipt, OFTReceipt, SendParam
} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title ISourceCore
 * @dev Main contract for the system, implementing the ERC4626 interface. It allows users to deposit assets and receive shares.
 *
 * @dev The primary distinction from the standard ERC4626 is the delayed withdrawal process, which works as follows:
 *    1. If a user requests a withdrawal at time `t`
 *    2. The user can claim the withdrawal no earlier than:
 *       `t + (epochDuration - t % epochDuration) % epochDuration + withdrawalDelay`
 *
 * During this delay, the designated system operator is expected to initiate the necessary transactions in the TargetCore contract,
 * ensuring liquidity is extracted from MultiVault on the target chain and transferred back to the source chain for the user’s claim.
 */
interface ISourceCore is ISourceCoreStorage {
    /**
     * @notice Initializes the SourceCore contract.
     * @dev Can only be called once by the contract deployer.
     * @param params Initialization parameters containing required settings and addresses.
     */
    function initialize(InitParams calldata params) external;

    /**
     * @notice Requests a withdrawal of the specified number of shares from SourceCore.
     * @dev Transfers the specified number of shares to the `WithdrawalQueue` contract and registers the withdrawal request in it.
     * @param shares The number of shares to withdraw.
     */
    function requestWithdrawal(uint256 shares) external;

    /**
     * @notice Transfers tokens via OFT (Omnichain Fungible Token) to the target chain through LayerZero.
     * @dev Can only be called by an address with the `PUSH_ROLE`.
     * @dev Requires a non-zero `msg.value` for LayerZero gas fees.
     * @return assets The number of assets transferred to the `targetCore` contract.
     */
    function pushToTarget() external payable returns (uint256 assets);

    /**
     * @notice Transfers assets from the SourceCore contract balance to the WithdrawalQueue to fulfill pending withdrawal requests.
     * @dev Can only be called by the `WithdrawalQueue` contract.
     * @param shares The number of shares to burn for the operation.
     * @param assets The number of assets to transfer.
     */
    function pull(uint256 shares, uint256 assets) external;

    /**
     * @notice Emitted when a withdrawal request is made.
     * @param caller The address that initiated the withdrawal request.
     * @param shares The number of shares requested for withdrawal.
     */
    event WithdrawalRequested(address indexed caller, uint256 indexed shares);

    /**
     * @notice Emitted when assets are successfully transferred to the target chain.
     * @param assets The number of transferred assets.
     * @param msgReceipt Messaging receipt details for the transaction.
     * @param oftReceipt OFT-specific receipt details for the transaction.
     */
    event PushToTarget(uint256 indexed assets, MessagingReceipt msgReceipt, OFTReceipt oftReceipt);

    /**
     * @notice Emitted when assets are pulled from SourceCore for withdrawal processing.
     * @param caller The address that initiated the pull request.
     * @param shares The number of burned shares for the pull request.
     * @param assets The number of assets transferred.
     */
    event Pull(address indexed caller, uint256 indexed shares, uint256 indexed assets);
}
