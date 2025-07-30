// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import "../interfaces/core/ISourceCore.sol";
import "../interfaces/core/ITargetCore.sol";
import "../interfaces/helpers/IBalanceChecker.sol";

contract MellowInteropBalanceChecker is IBalanceChecker {
    /// @inheritdoc IBalanceChecker
    /// @dev `token` is the address of the source core (ERC4626 vault), not the token itself.
    function tokenBalances(address token, address[] calldata addresses) external view returns (uint256[] memory result) {
        ISourceCore sourceCore = ISourceCore(token);
        token = sourceCore.asset();
        result = new uint256[](addresses.length);

        uint256 decimals = IERC20Metadata(token).decimals();
        uint256 totalSupply = sourceCore.totalSupply();
        uint256 totalAssets = Math.mulDiv(totalSupply, sourceCore.oracle().value(), sourceCore.D18());
        for (uint256 i = 0; i < addresses.length; i++) {
            uint256 shares = sourceCore.balanceOf(addresses[i]);
            uint256 underlyingBalance = Math.mulDiv(
                shares,
                totalAssets + 1,
                totalSupply + 1
            );
            result[i] = _normalizeDecimals(decimals, underlyingBalance);
        }
    }

    /// @inheritdoc IBalanceChecker
    function batchTokenBalances(address[] calldata sources, address[] calldata addresses)
        external
        view
        returns (uint256[] memory result)
    {
        result = new uint256[](addresses.length);
        for (uint256 i = 0; i < sources.length; i++) {
            uint256[] memory balances = this.tokenBalances(sources[i], addresses);
            for (uint256 j = 0; j < addresses.length; j++) {
                result[j] += balances[j];
            }
        }
    }

    /// @notice Normalize the balance to 18 decimals
    function _normalizeDecimals(uint256 decimals, uint256 balance) private pure returns (uint256) {
        if (decimals < 18) {
            return balance * (10 ** (18 - decimals));
        } else if (decimals > 18) {
            return balance / (10 ** (decimals - 18));
        }
        return balance;
    }
}
