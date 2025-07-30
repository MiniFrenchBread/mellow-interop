// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

interface IBalanceChecker {
    /// @notice Get the balance of a token for a list of addresses
    /// @param token The address of the token
    /// @param addresses The addresses to get the balance of
    /// @return result The balances of the tokens for the addresses
    function tokenBalances(address token, address[] calldata addresses)
        external
        view
        returns (uint256[] memory result);

    /// @notice Get the balances for multiple addresses across multiple tokens
    /// @param sources The addresses of the tokens
    /// @param addresses The addresses to get the balance of
    /// @return result The balances of the tokens for the addresses
    function batchTokenBalances(address[] calldata sources, address[] calldata addresses)
        external
        view
        returns (uint256[] memory result);
}
