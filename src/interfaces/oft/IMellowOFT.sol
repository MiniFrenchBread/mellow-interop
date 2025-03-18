// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {OFT} from "@layerzerolabs/oft-evm/contracts/OFT.sol";
import {IOFT} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IMellowOFT
 * @dev Interface for the MellowOFT contract that extends the OFT standard.
 *
 * The MellowOFT contract integrates LayerZero's OFT (Omnichain Fungible Token) standard to enable seamless
 * cross-chain asset transfers.
 */
interface IMellowOFT is IOFT, IERC20 {
    /**
     * @notice Removes `dust` (by modulo `decimalConversionRate`) from the specified amount of assets.
     */
    function removeDust(uint256 amountLD_) external view returns (uint256);
}
