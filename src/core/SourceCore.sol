// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../adapters/CrosschainAdapter.sol";

contract SourceCore is CrosschainAdapter {
    constructor(address owner_) Ownable(owner_) {}

    function _receiveMessage(bytes32 chainId, bytes32 sender, uint256 value, bytes calldata data)
        internal
        virtual
        override
    {}

    function _sendMessage(bytes32 chainId, bytes32 receiver, uint256 value, bytes calldata data)
        internal
        virtual
        override
    {}

    function deposit(uint256 assets, address receiver) external returns (uint256 batchId) {}

    function pushDepositBatch(uint256 batchId, uint256 value) external payable {}

    function _completeDepositBatch(uint256 batchId, uint256 value) internal {}

    function claimDeposits(uint256[] calldata batchIds, uint256 recipient) external returns (uint256 shares) {}

    function withdraw(address shares, address receiver) external returns (uint256 batchId) {}

    function pushWithdrawalBatch(uint256 batchId, uint256 value) external payable {}

    function _completeWithdrawalBatch() internal {}

    function claimWithdrawals(uint256[] calldata batchIds, uint256 recipient) external returns (uint256 assets) {}
}

// import "./BaseCore.sol";

// contract MellowL2Core is BaseCore {
//     using SafeERC20 for IERC20;

//     uint32 private immutable _dstEid;
//     IERC20 public immutable underlyingToken;

//     constructor(address _token, address _lzEndpoint, address _delegate, string memory name_, string memory symbol_)
//         OApp(_lzEndpoint, _delegate)
//         Ownable(_delegate)
//         BaseCore(name_, symbol_)
//     {
//         underlyingToken = IERC20(_token);
//         _dstEid = 1;
//     }

//     function deposit(uint256 assets, address receiver) external returns (uint256 batchId) {
//         require(assets > 0, "MellowL2Core: INVALID_AMOUNT");
//         require(receiver != address(0), "MellowL2Core: INVALID_RECEIVER");
//         batchId = depositBatches;
//         underlyingToken.safeTransferFrom(msg.sender, address(this), assets);
//         Request storage deposit_ = _deposits[batchId];
//         if (deposit_.status == Status.CLOSED) {
//             deposit_.status = Status.OPEN;
//             deposit_.totalRequested = assets;
//         } else {
//             deposit_.totalRequested += assets;
//         }
//         deposit_.requests[receiver] += assets;
//     }

//     function pushDepositBatch(uint256 batchId, uint256 fee)
//         external
//         payable
//         returns (MessagingReceipt memory receipt)
//     {
//         Request storage deposit_ = _deposits[batchId];
//         require(deposit_.status == Status.OPEN, "MellowL2Core: INVALID_STATUS");
//         uint256 totalRequested = deposit_.totalRequested;
//         require(totalRequested > 0, "MellowL2Core: INVALID_AMOUNT");
//         require(msg.value == fee && fee > 0, "MellowL2Core: INVALID_FEE");
//         deposit_.status = Status.PENDING;
//         uint256 batches_ = depositBatches;
//         if (batchId == batches_) {
//             batches_++;
//             _deposits[batches_].status = Status.OPEN;
//             depositBatches = batches_;
//         }

//         // TODO: fix
//         receipt = _lzSend(
//             _dstEid,
//             abi.encode(batchId, totalRequested),
//             new bytes(0),
//             MessagingFee({nativeFee: fee, lzTokenFee: 0}),
//             address(this)
//         );
//     }

//     function completeDepositBatch(uint256 batchId, uint256 amount) external {
//         Request storage deposit_ = _deposits[batchId];
//         require(deposit_.status == Status.PENDING, "MellowL2Core: INVALID_STATUS");
//         deposit_.totalProcessed = amount;
//         deposit_.status = Status.SUCCESS;
//     }

//     function _failDepositBatch(uint256 batchId) internal {
//         _deposits[batchId].status = Status.FAILED;
//     }

//     function _lzReceive(
//         Origin calldata _origin,
//         bytes32 _guid,
//         bytes calldata _message,
//         address _executor,
//         bytes calldata _extraData
//     ) internal virtual override {
//         // TODO: implement
//     }
// }

// /*
//     deposit process:
//         step 1: accumulate deposits into a single batch:
//             functions used: l2:Deposit

//         step 2: push deposits to the mainnet:
//             functions used: l2:PushDepositBatch, l1:pushIntoDepositQueue, l2:receiveDepositQueueResponse

//         step 3: process deposits:
//             functions used: l1:processDepositBatch, l2:completeDepositBatch, l1:receiveDepositBatchCompletionResponse

//         step 4: claim deposits:
//             functions used: l2:claimDeposits(batches[], receiver)

//     withdrawal process:
//         step 1: accumulate withdrawals into a signle batch:
//             functions used: l2:withdraw

//         step2: push withdrawals to l1 and put them into withdrawal queue
//             functions used: l2:pushWithdrawalBatch, l1:pushIntoWithdrawalQueue, l2:receiveWithdrawalQueueResponse

//         step 3: process withdrawals:
//             functions used: l1:processWithdrawalBatch, l2:completeWithdrawalBatch, l1:receiveWithdrawalBatchCompletionResponse

//         step 4: claim withdrawals:
//             functions used: l2:claimWithdrawals(batches[], receiver)

//         + error handling...
// */
