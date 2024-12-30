// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "./Core.sol";
import "./TargetCore.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract SourceCore is Core {
    using SafeERC20 for IERC20;

    enum Status {
        CLOSED,
        OPEN,
        PENDING,
        COMPLETED
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

    address public burner;

    uint256 public depositBatches;
    uint256 public redeemBatches;

    uint256 public minDepositValue;
    uint256 public minPushDepositBatchValue;
    uint256 public minRedeemValue;
    uint256 public minPushRedeemBatchValue;

    mapping(uint256 batchId => Request) private _deposits;
    mapping(uint256 batchId => Request) private _redeems;

    mapping(uint256 messageId => bool) public isMessageReceived;

    constructor(address owner_, address underlying, string memory name_, string memory symbol_)
        Core(owner_, name_, symbol_)
    {
        underlyingAsset = IERC20(underlying);
    }

    function setBurner(address burner_) external onlyOwner {
        burner = burner_;
    }

    function setValues(
        uint256 minDepositValue_,
        uint256 minPushDepositBatchValue_,
        uint256 minRedeemValue_,
        uint256 minPushRedeemBatchValue_
    ) external onlyOwner {
        minDepositValue = minDepositValue_;
        minPushDepositBatchValue = minPushDepositBatchValue_;
        minRedeemValue = minRedeemValue_;
        minPushRedeemBatchValue = minPushRedeemBatchValue_;
    }

    function _receiveMessage(uint256, /* value */ bytes memory data) internal virtual override {
        (MessageType messageType, uint256 messageId, uint256 batchId, uint256 assets, uint256 shares) =
            abi.decode(data, (MessageType, uint256, uint256, uint256, uint256));
        isMessageReceived[messageId] = true;
        if (messageType == MessageType.DEPOSIT) {
            Request storage deposit_ = _deposits[batchId];
            require(deposit_.status == Status.PENDING, "SourceCore: INVALID_STATUS");
            deposit_.status = Status.COMPLETED;
            deposit_.processed = shares;
        } else if (messageType == MessageType.CLAIM) {
            Request storage redeem_ = _redeems[batchId];
            Status status = redeem_.status;
            require(status == Status.PENDING || status == Status.COMPLETED, "SourceCore: INVALID_STATUS");
            if (status == Status.PENDING) {
                // Here, competed means that some withdrawals from subvaults have been processed.
                // While it is still possible to have some pending withdrawals,
                // we would like to allow users to withdraw such assets as soon as possible.
                redeem_.status = Status.COMPLETED;
                redeem_.processed = assets;
            } else {
                redeem_.processed += assets;
            }
            asset.burn(address(this), shares);
        } else if (messageType == MessageType.SLASHING) {
            asset.burn(address(this), shares);
            underlyingAsset.safeTransfer(burner, assets);
        } else {
            revert("SourceCore: INVALID_MESSAGE_TYPE");
        }
    }

    function deposit(uint256 assets, address receiver) external payable returns (uint256 batchId) {
        require(msg.value >= minDepositValue, "SourceCore: INVALID_VALUE");
        underlyingAsset.safeTransferFrom(msg.sender, address(this), assets);

        batchId = depositBatches;
        Request storage deposit_ = _deposits[batchId];
        if (deposit_.status == Status.CLOSED) {
            deposit_.status = Status.OPEN;
            deposit_.requested = assets;
            deposit_.accountRequest[receiver] = assets;
            deposit_.value = msg.value;
        } else if (deposit_.status == Status.OPEN) {
            deposit_.requested += assets;
            deposit_.accountRequest[receiver] += assets;
            deposit_.value += msg.value;
        } else {
            batchId++;
            depositBatches = batchId;
            deposit_ = _deposits[batchId];
            deposit_.status = Status.OPEN;
            deposit_.requested = assets;
            deposit_.accountRequest[receiver] = assets;
            deposit_.value = msg.value;
        }
    }

    function pushDepositBatch(uint256 batchId) external payable {
        Request storage deposit_ = _deposits[batchId];
        require(deposit_.status == Status.OPEN, "SourceCore: INVALID_STATUS");
        require(deposit_.requested > 0, "SourceCore: INVALID_AMOUNT");
        uint256 depositValue = deposit_.value + msg.value;
        require(depositValue >= minPushDepositBatchValue, "SourceCore: INVALID_VALUE");
        depositBatches++;
        deposit_.status = Status.PENDING;
        _sendMessage(depositValue, abi.encode(MessageType.DEPOSIT, batchId, deposit_.requested));
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

    function redeem(uint256 shares, address receiver) external payable returns (uint256 batchId) {
        require(msg.value >= minRedeemValue, "SourceCore: INVALID_VALUE");
        asset.burn(msg.sender, shares);
        batchId = redeemBatches;
        Request storage redeem_ = _redeems[batchId];
        if (redeem_.status == Status.CLOSED) {
            redeem_.status = Status.OPEN;
            redeem_.requested = shares;
            redeem_.accountRequest[receiver] = shares;
            redeem_.value = msg.value;
        } else if (redeem_.status == Status.OPEN) {
            redeem_.requested += shares;
            redeem_.accountRequest[receiver] += shares;
            redeem_.value += msg.value;
        } else {
            batchId++;
            redeemBatches = batchId;
            redeem_ = _redeems[batchId];
            redeem_.status = Status.OPEN;
            redeem_.requested = shares;
            redeem_.accountRequest[receiver] = shares;
            redeem_.value = msg.value;
        }
    }

    function pushRedeemBatch(uint256 batchId) external payable {
        Request storage redeem_ = _redeems[batchId];
        require(redeem_.status == Status.OPEN, "SourceCore: INVALID_STATUS");
        require(redeem_.requested > 0, "SourceCore: INVALID_AMOUNT");
        uint256 redeemValue = redeem_.value + msg.value;
        require(redeemValue >= minPushRedeemBatchValue, "SourceCore: INVALID_VALUE");
        redeemBatches++;
        redeem_.status = Status.PENDING;
        _sendMessage(redeemValue, abi.encode(MessageType.REDEEM, batchId, redeem_.requested));
    }

    function claimRedeems(uint256[] calldata batchIds, address recipient) external returns (uint256 assets) {
        address sender = msg.sender;
        for (uint256 i = 0; i < batchIds.length; i++) {
            Request storage redeem_ = _redeems[batchIds[i]];
            if (redeem_.status != Status.COMPLETED) {
                continue;
            }
            uint256 accountRequest = redeem_.accountRequest[sender];
            if (accountRequest == 0) {
                continue;
            }
            uint256 due = Math.mulDiv(redeem_.processed, redeem_.requested, accountRequest);
            uint256 claimed = redeem_.accountClaimed[sender];
            if (claimed >= due) {
                continue;
            }
            uint256 leftover = due - claimed;
            assets += leftover;
            redeem_.accountClaimed[sender] = due;
        }
        if (assets != 0) {
            underlyingAsset.safeTransfer(recipient, assets);
        }
    }
}
