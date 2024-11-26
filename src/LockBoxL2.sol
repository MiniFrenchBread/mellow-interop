// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.25;

import "./interfaces/LayerZeroImports.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "src/interfaces/ILockBoxL2.sol";

contract LockBoxL2 is ILockBoxL2, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using OptionsBuilder for bytes;

    address public immutable transmitter;
    address public immutable underlying;
    IStargate public immutable stargate;
    uint32 public immutable dstEid;
    address public immutable vaultOFTL2;

    bool private _isDepositLocked = false;
    uint256 private constant MAX_BATCH_LENGTH = 50;
    bool private immutable _isNative;

    /// @dev current pending deposits are made by users at L2
    mapping(uint256 => Deposit) private _pendingDepositQueue;
    uint256 private _firstPendingDeposit = 1;
    uint256 private _lastPendingDeposit = 0;
    /// @dev batches wait for mint on L2, because they are sent to L1
    mapping(bytes32 => DepositBatch) private _waitingDepositBatch;

    constructor(address owner, LayerZeroData memory lzData) Ownable(owner) {
        underlying = lzData.underlying;
        transmitter = lzData.transmitter;
        stargate = IStargate(lzData.stargate);
        require(stargate.token() == underlying, "inconsistent tokens");
        _isNative = (underlying == address(0));
        dstEid = lzData.dstEid;
        vaultOFTL2 = lzData.vaultOFTL2;
    }

    function setDepositLockedState(bool depositState) external onlyOwner {
        if (depositState == _isDepositLocked) {
            return;
        }
        _isDepositLocked = depositState;
        emit DepositLockedStateUpdated(depositState, !depositState);
    }

    /// @notice Sends to L1 instantly or save as pending
    function depositToL1(uint256 amount, address to, bool instant) external payable {
        require(!_isDepositLocked, "locked");
        require(amount > 0, "zero amount");
        require(to != address(0), "zero address");

        if (_isNative) {
            require(msg.value > amount, "insufficient value");
        } else {
            IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        }

        Deposit memory deposit = Deposit({to: to, amount: amount});

        if (instant) {
            /// @dev if user want to send asset into L1 instantly
            (bytes32 batchId,) = _pendingToWaiting(deposit);
            _sendPendingToL1(batchId);
        } else {
            /// @dev push pending deposit
            _pushPendingDeposit(deposit);
        }
    }

    function distributeDeposit(bytes32 batchId, uint256 amountLD) external {
        require(msg.sender == vaultOFTL2, "forbidden");
        require(_waitingDepositBatch[batchId].status != Status.Done, "done");
        require(_waitingDepositBatch[batchId].deposits.length == 0, "empty");

        if (amountLD == 0) {
            /// @dev actually failed deposit on L1
            _waitingDepositBatch[batchId].status = Status.Ready;
            return;
        }
        require(amountLD <= IERC20(vaultOFTL2).balanceOf(address(this)), "insufficient amountLD");

        Deposit memory deposit;
        uint256 batchAmount = _waitingDepositBatch[batchId].amount;
        for (uint256 i = 0; i < _waitingDepositBatch[batchId].deposits.length; i++) {
            deposit = _waitingDepositBatch[batchId].deposits[i];
            uint256 lpAmount =
                Math.mulDiv(deposit.amount, amountLD, batchAmount, Math.Rounding.Floor);

            IERC20(vaultOFTL2).transfer(deposit.to, lpAmount);

            delete _waitingDepositBatch[batchId].deposits[i];

            emit OFTDepositFinalized(batchId, deposit.to, deposit.amount, lpAmount);
        }

        _waitingDepositBatch[batchId].status = Status.Done;
    }

    /// @notice permissionless function to trigger send message into L1 with all pending assets
    function sendPendingToL1()
        external
        returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt)
    {
        (bytes32 batchId,) = _pendingToWaiting();
        return _sendPendingToL1(batchId);
    }

    /// @notice permissionless function to trigger send message into L1 with for waiting batchId
    /// @dev used in case of failing
    function sendWaitingToL1(bytes32 batchId)
        external
        returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt)
    {
        return _sendPendingToL1(batchId);
    }

    /// @notice Create waiting batch from provided deposit
    function _pendingToWaiting(Deposit memory deposit)
        internal
        returns (bytes32 batchId, uint256 amount)
    {
        require(deposit.amount > 0, "zero amount");

        batchId = keccak256(abi.encode(deposit, block.number));

        /// @dev prevent more than one deposit at one block
        require(_waitingDepositBatch[batchId].deposits.length == 0, " forbidden");

        amount = deposit.amount;

        _waitingDepositBatch[batchId].deposits.push(deposit);
        _waitingDepositBatch[batchId].amount = amount;
        _waitingDepositBatch[batchId].status = Status.Ready;
    }

    /// @notice Create waiting batch from all current pending deposits
    function _pendingToWaiting() internal nonReentrant returns (bytes32 batchId, uint256 amount) {
        uint256 queueLength = _pendingDepositQueueLength();
        require(queueLength > 0, "empty queue");

        queueLength = queueLength > MAX_BATCH_LENGTH ? MAX_BATCH_LENGTH : queueLength;

        /// @dev unique batchId
        batchId = keccak256(abi.encode(_firstPendingDeposit, queueLength, block.number));

        /// @dev update waiting amounts, and clear pending
        Deposit memory deposit;
        for (uint256 i = 0; i < queueLength; i++) {
            deposit = _popPendingDeposit();
            amount += deposit.amount;
            _waitingDepositBatch[batchId].deposits.push(deposit);
        }

        _waitingDepositBatch[batchId].amount = amount;
        _waitingDepositBatch[batchId].status = Status.Ready;
    }

    /// @notice sends cross-chain message with provided deposits and, clears them and saves as waiting batch
    function _sendPendingToL1(bytes32 batchId)
        internal
        nonReentrant
        returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt)
    {
        uint256 amount = _waitingDepositBatch[batchId].amount;
        require(amount > 0, "zero amount");
        require(_waitingDepositBatch[batchId].status == Status.Ready, "forbidden");

        if (!_isNative) {
            if (IERC20(underlying).allowance(address(this), address(stargate)) < amount) {
                IERC20(underlying).safeIncreaseAllowance(address(stargate), amount);
            }
        }

        (uint256 valueToSend, SendParam memory sendParam, MessagingFee memory messagingFee) =
            _quoteSendInfo(batchId);

        require(valueToSend < address(this).balance);

        (msgReceipt, oftReceipt,) = IStargate(stargate).sendToken{value: valueToSend}(
            sendParam,
            messagingFee,
            tx.origin /* refund address to EOA transaction sender (bot or depositor) */
        );

        _waitingDepositBatch[batchId].status = Status.SentToL1;

        /// @dev [TBD] add checks for receipt
    }

    function _quoteSendInfo(bytes32 batchId)
        internal
        view
        returns (uint256 valueToSend, SendParam memory sendParam, MessagingFee memory messagingFee)
    {
        uint128 length = uint128(_waitingDepositBatch[batchId].deposits.length);
        uint256 amount = _waitingDepositBatch[batchId].amount;
        bytes memory extraOptions =
            OptionsBuilder.newOptions().addExecutorLzComposeOption(0, 1000000, 0); // gas limit on L1: receive(~50k) + vault deposit (~600k) + send (~100k)

        sendParam = SendParam({
            dstEid: dstEid, // Destination endpoint ID.
            to: bytes32(uint256(uint160(transmitter))), // Recipient address.
            amountLD: amount, // Amount to send in local decimals.
            minAmountLD: amount, // Minimum amount to send in local decimals.
            extraOptions: extraOptions, // Additional options supplied by the caller to be used in the LayerZero message.
            composeMsg: abi.encode(batchId, amount, length), // The composed message for the send() operation.
            /// @dev if _cmd is empty, Taxi mode. Otherwise, Bus mode
            oftCmd: "" // https://github.com/stargate-protocol/stargate-v2/blob/01df0a2b9ec399f878619b992d6607386e6a5573/packages/stg-evm-v2/src/StargateBase.sol#L642
        });

        (,, OFTReceipt memory receipt) = stargate.quoteOFT(sendParam);
        sendParam.minAmountLD = receipt.amountReceivedLD;

        messagingFee = stargate.quoteSend(sendParam, false);
        valueToSend = messagingFee.nativeFee;

        if (_isNative) {
            valueToSend += sendParam.amountLD;
        }
    }

    function _pendingDepositQueueLength() private view returns (uint256) {
        if (_lastPendingDeposit <= _firstPendingDeposit) {
            return 0;
        }
        return _lastPendingDeposit - _firstPendingDeposit;
    }

    function _pushPendingDeposit(Deposit memory deposit) private {
        _pendingDepositQueue[++_lastPendingDeposit] = deposit;
    }

    function _popPendingDeposit() private returns (Deposit memory deposit) {
        uint256 first = _firstPendingDeposit;
        require(_lastPendingDeposit >= first, "empty");
        deposit = _pendingDepositQueue[first];
        delete _pendingDepositQueue[first];
        _firstPendingDeposit = first + 1;
    }
}
