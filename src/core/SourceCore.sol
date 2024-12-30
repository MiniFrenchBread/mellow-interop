// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "./Core.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract SourceCore is Core {
    using SafeERC20 for IERC20;

    enum Status {
        CLOSED, // no deposits allowed yet
        OPEN, // deposits allowed
        PENDING, // no deposits allowed, waiting for processing
        COMPLETED // deposits processed, waiting for claims

    }

    enum SourceMessageType {
        DEPOSIT,
        WITHDRAWAL,
        CLAIM
    }

    enum TargetMessageType {
        DEPOSIT,
        WITHDRAWAL,
        DEPOSIT_SUCCESS,
        WITHDRAWAL_SUCCESS
    }

    struct Request {
        uint256 value;
        uint256 requested;
        uint256 processed;
        uint256 claimed;
        mapping(address account => uint256) accountRequest;
        mapping(address account => uint256) accountClaimed;
        Status status;
    }

    IERC20 public immutable underlyingAsset;

    uint256 public depositBatches;
    uint256 public minDepositValue;
    uint256 public minPushDepositsValue;
    uint256 public minWithdrawalValue;
    uint256 public minPushWithdrawalsValue;

    mapping(uint256 batchId => Request) private _deposits;
    mapping(uint256 batchId => Request) private _withdrawals;

    mapping(uint256 messageId => bool) public processedMessages;

    constructor(address owner_, address underlying, string memory name_, string memory symbol_)
        Core(owner_, name_, symbol_)
    {
        underlyingAsset = IERC20(underlying);
    }

    function _receiveMessage(uint256, /* value */ bytes memory data) internal virtual override {
        (SourceMessageType messageType, uint256 messageId, uint256 batchId, uint256 amount) =
            abi.decode(data, (SourceMessageType, uint256, uint256, uint256));
        if (messageType == SourceMessageType.DEPOSIT) {
            Request storage deposit_ = _deposits[batchId];
            require(deposit_.status == Status.PENDING, "SourceCore: INVALID_STATUS");
            deposit_.status = Status.COMPLETED;
            deposit_.processed = amount;
            processedMessages[messageId] = true;
        } else if (messageType == SourceMessageType.WITHDRAWAL) {
            Request storage withdrawal_ = _withdrawals[batchId];
            require(withdrawal_.status == Status.PENDING, "SourceCore: INVALID_STATUS");
            withdrawal_.status = Status.COMPLETED;
            // We probably won't have such a `COMPLETED` status for withdrawal at all due to d
            withdrawal_.processed = amount;
            asset.burn(address(this), amount);
            processedMessages[messageId] = true;
        } else if (messageType == SourceMessageType.CLAIM) {} else {
            revert("SourceCore: INVALID_MESSAGE_TYPE");
        }
    }

    function _sendMessage(uint256 value, bytes memory data) internal virtual override {
        IAdapter(adapter).send{value: value}(pairedChainId, pairedCoreAdapterAddress, value, data);
    }

    function deposit(uint256 assets, address receiver, uint256 value) external payable returns (uint256 batchId) {
        require(value >= minDepositValue, "SourceCore: INVALID_VALUE");
        underlyingAsset.safeTransferFrom(msg.sender, address(this), assets);

        batchId = depositBatches;
        Request storage deposit_ = _deposits[batchId];
        if (deposit_.status == Status.CLOSED) {
            deposit_.status = Status.OPEN;
            deposit_.requested = assets;
            deposit_.accountRequest[receiver] = assets;
            deposit_.value += value;
        } else if (deposit_.status == Status.OPEN) {
            deposit_.requested += assets;
            deposit_.accountRequest[receiver] += assets;
            deposit_.value += value;
        } else {
            batchId++;
            depositBatches = batchId;
            deposit_ = _deposits[batchId];
            deposit_.status = Status.OPEN;
            deposit_.requested = assets;
            deposit_.accountRequest[receiver] = assets;
            deposit_.value = value;
        }
    }

    function pushDepositBatch(uint256 batchId, uint256 value) external payable {
        Request storage deposit_ = _deposits[batchId];
        require(deposit_.status == Status.OPEN, "SourceCore: INVALID_STATUS");
        require(deposit_.requested > 0, "SourceCore: INVALID_AMOUNT");
        require(msg.value == value && value + deposit_.value >= minPushDepositsValue, "SourceCore: INVALID_VALUE");
        depositBatches++;
        deposit_.status = Status.PENDING;
        _sendMessage(value, abi.encode(TargetMessageType.DEPOSIT, batchId, deposit_.requested));
    }

    function claimDeposits(uint256[] calldata batchIds, address recipient) external returns (uint256 shares) {
        address sender = msg.sender;
        for (uint256 i = 0; i < batchIds.length; i++) {
            Request storage deposit_ = _deposits[batchIds[i]];
            if (deposit_.status != Status.COMPLETED) {
                continue;
            }
            uint256 accountRequest = deposit_.accountRequest[sender];
            if (accountRequest == 0) {
                continue;
            }
            uint256 due = Math.mulDiv(deposit_.processed, deposit_.requested, accountRequest);
            uint256 claimed = deposit_.accountClaimed[sender];
            if (claimed >= due) {
                continue;
            }
            uint256 leftover = due - claimed;
            shares += leftover;
            deposit_.accountClaimed[sender] = due;
        }
        if (shares != 0) {
            asset.mint(recipient, shares);
        }
    }

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
