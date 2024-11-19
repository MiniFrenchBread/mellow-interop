// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.25;

import {ILockBoxL2} from "./interfaces/ILockBoxL2.sol";
import {IOracleL2} from "./interfaces/IOracleL2.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/utils/math/Math.sol";
import {OFT} from "lib/layerzero-v2/packages/layerzero-v2/evm/oapp/contracts/oft/OFT.sol";

contract VaultOFTL2 is OFT {
    using SafeERC20 for IERC20;
    using Math for uint256;

    uint256 public immutable Q96 = 2 ** 96;

    address public immutable underlying;
    ILockBoxL2 public immutable lockBoxL2;
    IOracleL2 public immutable oracleL2;

    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _delegate,
        address _underlying,
        address _lockBoxL2,
        address _oracleL2
    ) OFT(_name, _symbol, _lzEndpoint, _delegate) {
        underlying = _underlying;
        lockBoxL2 = ILockBoxL2(_lockBoxL2);
        oracleL2 = IOracleL2(_oracleL2);
    }

    /// @dev sends to LockBoxL2 and mint tokens,
    function deposit(uint256 amount, address to, uint256 minLpAmount) external {
        uint256 ratioX96 = oracleL2.ratioX96();
        uint256 lpAmount = Math.mulDiv(amount, ratioX96, Q96);
        require(lpAmount >= minLpAmount);
        IERC20(underlying).safeTransferFrom(msg.sender, address(lockBoxL2), amount);
        _mint(to, lpAmount);
    }
}
