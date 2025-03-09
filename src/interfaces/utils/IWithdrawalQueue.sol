// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import {ISourceCore} from "../core/ISourceCore.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

interface IWithdrawalQueue {
    function SET_WITHDRAWAL_DELAY_ROLE() external view returns (bytes32);

    function sourceCore() external view returns (ISourceCore);

    function asset() external view returns (IERC20);

    function epochDuration() external view returns (uint256);

    function initTimestamp() external view returns (uint256);

    function epochIterator() external view returns (uint256);

    function withdrawalDelay() external view returns (uint256);

    function sharesOf(uint256 epoch, address account) external view returns (uint256);

    function withdrawals(uint256 epoch) external view returns (uint256);

    function shares(uint256 epoch) external view returns (uint256);

    function totalShares() external view returns (uint256);

    function setWithdrawalDelay(uint256 withdrawalDelay_) external;

    function request(address account, uint256 shares_) external;

    function claim(uint256 epoch, address receiver) external returns (uint256 assets);

    function handleEpoch() external;

    function currentEpoch() external view returns (uint256);

    event Request(uint256 indexed epoch, address indexed account, uint256 indexed shares);

    event Claim(uint256 indexed epoch, address indexed account, uint256 indexed assets);

    event HandleEpoch(uint256 indexed epoch, uint256 indexed shares, uint256 indexed assets);

    event WithdrawalDelaySet(uint256 indexed withdrawalDelay_);
}
