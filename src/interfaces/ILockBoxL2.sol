// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.25;

import {
    MessagingFee,
    MessagingReceipt,
    OFTReceipt,
    SendParam
} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";

interface ILockBoxL2 {
    event DepositLockedStateUpdated(bool currentState, bool previousState);

    event OFTDepositFinalized(
        bytes32 indexed batchId, address indexed to, uint256 amount, uint256 lpAmount
    );

    struct Deposit {
        address to;
        uint256 amount;
    }

    enum Status {
        Done,
        Ready,
        SentToL1
    }

    struct DepositBatch {
        uint256 amount;
        Status status;
        Deposit[] deposits;
    }

    /// @notice sends to LockBoxL2 and then send to L1 instantly or save at pending array
    function depositToL1(uint256 amount, address to, bool instant) external payable;

    /// @notice permissionless function to trigger send message with assets into L1
    function sendPendingToL1()
        external
        returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt);

    function distributeDeposit(bytes32 batchId, uint256 amountLD) external;
}
