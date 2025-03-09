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

interface ITargetCore is ITargetCoreStorage {
    function initialize(InitParams calldata params) external;

    function deposit(uint256 assets) external;

    function redeem(uint256 shares) external;

    function claim(bytes calldata data) external;

    function pushToSource(uint256 assets) external payable;

    event Deposit(uint256 assets);

    event Redeem(uint256 shares);

    event Claim(uint256 assets, bytes data);

    event PushToSource(uint256 assets, MessagingReceipt msgReceipt, OFTReceipt oftReceipt);
}
