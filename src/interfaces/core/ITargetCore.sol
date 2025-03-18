// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import {IMellowOFT} from "../oft/IMellowOFT.sol";
import {ITargetCoreStorage} from "./ITargetCoreStorage.sol";
import {
    MessagingFee, MessagingReceipt, OFTReceipt, SendParam
} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title ITargetCore
 * @dev Contract responsible for interacting with MultiVault on the target chain.
 *
 * This contract facilitates transactions executed by trusted actors with the following roles:
 * - `TARGET_CORE:PUSH_ROLE`
 * - `TARGET_CORE:DEPOSIT_ROLE`
 * - `TARGET_CORE:REDEEM_ROLE`
 * - `TARGET_CORE:CLAIM_ROLE`
 */
interface ITargetCore is ITargetCoreStorage {
    /**
     * @notice Initializes the TargetCore contract.
     * @param params The initialization parameters containing necessary configurations.
     */
    function initialize(InitParams calldata params) external;

    /**
     * @notice Deposits assets into the MultiVault on the target chain.
     * @param assets The amount of assets to deposit.
     */
    function deposit(uint256 assets) external;

    /**
     * @notice Redeems a specified number of shares and withdraws corresponding assets.
     * @param shares The number of shares to redeem.
     */
    function redeem(uint256 shares) external;

    /**
     * @notice Claims rewards or funds from a specific data payload.
     * @param data Encoded data representing the claim details.
     */
    function claim(bytes calldata data) external;

    /**
     * @notice Transfers tokens back to the source chain using LayerZero.
     * @param assets The number of assets to transfer.
     */
    function pushToSource(uint256 assets) external payable;

    /**
     * @notice Emitted when a deposit is successfully processed.
     * @param assets The number of assets deposited.
     */
    event Deposit(uint256 assets);

    /**
     * @notice Emitted when shares are redeemed successfully.
     * @param shares The number of shares redeemed.
     */
    event Redeem(uint256 shares);

    /**
     * @notice Emitted when a claim is successfully processed.
     * @param assets The number of claimed assets.
     * @param data The associated data used for the claim.
     */
    event Claim(uint256 assets, bytes data);

    /**
     * @notice Emitted when assets are successfully transferred back to the source chain.
     * @param assets The number of transferred assets.
     * @param msgReceipt Messaging receipt details.
     * @param oftReceipt OFT-specific receipt details for the transfer.
     */
    event PushToSource(uint256 assets, MessagingReceipt msgReceipt, OFTReceipt oftReceipt);
}
