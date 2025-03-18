// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import {OFTAdapter, OFTCore} from "@layerzerolabs/oft-evm/contracts/OFTAdapter.sol";
import {
    IOFT,
    MessagingFee,
    MessagingReceipt,
    OFTReceipt,
    SendParam
} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title IMellowOFTAdapter
 * @dev Interface for the MellowOFTAdapter contract that extends the Omnichain Fungible Token (OFT) interface.
 *
 * The MellowOFTAdapter contract is responsible for integrating LayerZero's cross-chain messaging functionality
 * with Mellow's specific logic for handling token transfers, dust removal, and linking to the SourceCore contract.
 */
interface IMellowOFTAdapter is IOFT {
    /**
     * @notice Returns the address of the linked SourceCore contract.
     * @return The SourceCore contract address.
     */
    function sourceCore() external view returns (address);

    /**
     * @notice Initializes the MellowOFTAdapter contract by linking it to the SourceCore contract.
     * @dev Can only be called once to set the SourceCore contract reference.
     * @param sourceCore_ The address of the SourceCore contract.
     */
    function initialize(address sourceCore_) external;

    /**
     * @notice Removes `dust` (by modulo `decimalConversionRate`) from the specified amount of assets.
     */
    function removeDust(uint256 amountLD_) external view returns (uint256);
}
