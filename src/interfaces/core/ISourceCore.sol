// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {IMellowOFTAdapter} from "../oft/IMellowOFTAdapter.sol";
import {ISourceCoreStorage} from "./ISourceCoreStorage.sol";
import {
    MessagingFee, MessagingReceipt, OFTReceipt, SendParam
} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

interface ISourceCore is ISourceCoreStorage {
    function initialize(InitParams calldata params) external;

    function requestWithdrawal(uint256 shares) external;

    function pushToTarget() external payable returns (uint256 assets);

    function pull(uint256 shares, uint256 assets) external;

    event WithdrawalRequested(address indexed caller, uint256 indexed shares);

    event PushToTarget(uint256 indexed assets, MessagingReceipt msgReceipt, OFTReceipt oftReceipt);

    event Pull(address indexed caller, uint256 indexed shares, uint256 indexed assets);
}
