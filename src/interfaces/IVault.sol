// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";

interface IVault is IERC20 {
    /// @notice Deposits specified amounts of tokens into the vault in exchange for LP tokens.
    /// @dev Only accessible when deposits are unlocked.
    /// @param to The address to receive LP tokens.
    /// @param amounts An array specifying the amounts for each underlying token.
    /// @param minLpAmount The minimum amount of LP tokens to mint.
    /// @param deadline The time before which the operation must be completed.
    /// @param referralCode The referral code to use for the deposit.
    /// @return actualAmounts The actual amounts deposited for each underlying token.
    /// @return lpAmount The amount of LP tokens minted.
    function deposit(
        address to,
        uint256[] memory amounts,
        uint256 minLpAmount,
        uint256 deadline,
        uint256 referralCode
    ) external payable returns (uint256[] memory actualAmounts, uint256 lpAmount);

    function underlying() external view returns (address);
}
