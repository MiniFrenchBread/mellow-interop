// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import "./Core.sol";

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
        Status status;
        mapping(address account => uint256) accountRequest;
        mapping(address account => uint256) accountClaimed;
    }

    IERC20 public immutable underlyingAsset;

    // burner contract for slashing events
    address public burner;

    uint256 public depositBatches;
    uint256 public redeemBatches;

    uint256 public minDepositValue;
    uint256 public minPushDepositBatchValue;
    uint256 public minRedeemValue;
    uint256 public minPushRedeemBatchValue;

    uint256 public limit;

    bool public isDepositWhitelist;
    mapping(address account => bool) public depositorWhitelistStatus;

    bool public depositPause;
    bool public redeemPause;

    uint256 public pushDelay = 4 hours;

    mapping(uint256 batchId => uint256) public pushDepositsTimestamp;
    mapping(uint256 batchId => uint256) public pushRedeemsTimestamp;
    mapping(uint256 batchId => Request) private _deposits;
    mapping(uint256 batchId => Request) private _redeems;

    mapping(uint256 batchId => mapping(uint256 index => bool)) public isClaimCompleted;
    mapping(uint256 index => bool) public isSlashingCompleted;

    constructor(address owner_, address underlying, string memory name_, string memory symbol_)
        Core(owner_, name_, symbol_)
    {
        underlyingAsset = IERC20(underlying);
    }

    function initialize(
        address burner_,
        uint256 limit_,
        bool depositWhitelistStatus_,
        bool depositPause_,
        bool redeemPause_,
        uint256 pushDelay_,
        address adapter_
    ) external initializer {
        __init_Core(adapter_);
        __init_SourceCore(burner_, limit_, depositWhitelistStatus_, depositPause_, redeemPause_, pushDelay_);
    }

    function setBurner(address burner_) external onlyOwner {
        burner = burner_;
    }

    function setLimit(uint256 newLimit) external onlyOwner {
        limit = newLimit;
    }

    function setDepositWhitelist(bool status) external onlyOwner {
        isDepositWhitelist = status;
    }

    function setDepositorWhitelistStatus(address account, bool status) external onlyOwner {
        depositorWhitelistStatus[account] = status;
    }

    function setDepositPause(bool status) external onlyOwner {
        depositPause = status;
    }

    function setRedeemPause(bool status) external onlyOwner {
        redeemPause = status;
    }

    function setPushDelay(uint256 newPushDelay) external onlyOwner {
        pushDelay = newPushDelay;
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

    function _receiveMessage(
        IAdapter.MessageType messageType,
        bytes calldata message,
        bytes calldata /* extraOptions */
    ) internal virtual override {
        if (messageType == IAdapter.MessageType.DEPOSIT) {
            (uint256 batchId, uint256 amount) = abi.decode(message, (uint256, uint256));
            Request storage deposit_ = _deposits[batchId];
            if (deposit_.status != Status.PENDING) {
                revert InvalidStatus();
            }
            deposit_.status = Status.COMPLETED;
            deposit_.processed = amount;
        } else if (messageType == IAdapter.MessageType.CLAIM || messageType == IAdapter.MessageType.RETRY_CLAIM) {
            (uint256 batchId, uint256 index, uint256 amount) = abi.decode(message, (uint256, uint256, uint256));
            Request storage redeem_ = _redeems[batchId];
            if (isClaimCompleted[batchId][index]) {
                if (messageType != IAdapter.MessageType.RETRY_CLAIM) {
                    revert Forbidden();
                }
                return;
            }
            Status status = redeem_.status;
            if (status != Status.PENDING && status != Status.COMPLETED) {
                revert InvalidStatus();
            }
            if (status == Status.PENDING) {
                redeem_.status = Status.COMPLETED;
                redeem_.processed = amount;
            } else {
                redeem_.processed += amount;
            }
            isClaimCompleted[batchId][index] = true;
        } else if (messageType == IAdapter.MessageType.SLASHING || messageType == IAdapter.MessageType.RETRY_SLASHING) {
            (uint256 index, uint256 amount) = abi.decode(message, (uint256, uint256));
            if (isSlashingCompleted[index]) {
                if (messageType != IAdapter.MessageType.RETRY_SLASHING) {
                    revert Forbidden();
                }
                return;
            }
            isSlashingCompleted[index] = true;
            underlyingAsset.safeTransfer(burner, amount);
        } else {
            revert InvalidMessageType();
        }
    }

    function deposit(uint256 assets, address receiver) external payable returns (uint256 batchId) {
        if (depositPause || isDepositWhitelist && !depositorWhitelistStatus[msg.sender]) {
            revert Forbidden();
        }
        if (assets + underlyingAsset.balanceOf(address(this)) > limit) {
            revert LimitOverflow(limit, assets + underlyingAsset.balanceOf(address(this)));
        }

        if (msg.value < minDepositValue) {
            revert LimitUnderflow(minDepositValue, msg.value);
        }
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

    function pushDepositBatch(uint256 batchId, bytes calldata options, bytes calldata extraOptions) external payable {
        Request storage deposit_ = _deposits[batchId];
        if (deposit_.status != Status.OPEN) {
            revert InvalidStatus();
        }
        if (batchId != 0 && _deposits[batchId - 1].status != Status.COMPLETED) {
            revert InvalidStatus();
        }
        if (deposit_.requested == 0) {
            revert Forbidden();
        }
        uint256 depositValue = deposit_.value + msg.value;
        if (depositValue < minPushDepositBatchValue) {
            revert LimitUnderflow(minPushDepositBatchValue, depositValue);
        }
        depositBatches++;
        deposit_.status = Status.PENDING;
        deposit_.value = 0;
        pushDepositsTimestamp[batchId] = block.timestamp;
        _sendMessage(
            IAdapter.MessageType.DEPOSIT, abi.encode(batchId, deposit_.requested), options, extraOptions, depositValue
        );
    }

    function retryPushDepositBatch(uint256 batchId, bytes calldata options, bytes calldata extraOptions)
        external
        payable
    {
        Request storage deposit_ = _deposits[batchId];
        if (deposit_.status != Status.PENDING) {
            revert InvalidStatus();
        }
        if (deposit_.requested == 0) {
            revert Forbidden();
        }
        if (block.timestamp < pushDepositsTimestamp[batchId] + pushDelay) {
            revert Forbidden();
        }
        uint256 depositValue = msg.value;
        if (depositValue < minPushDepositBatchValue) {
            revert LimitUnderflow(minPushDepositBatchValue, depositValue);
        }
        pushDepositsTimestamp[batchId] = block.timestamp;
        _sendMessage(
            IAdapter.MessageType.RETRY_DEPOSIT,
            abi.encode(batchId, deposit_.requested),
            options,
            extraOptions,
            depositValue
        );
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
        if (redeemPause) {
            revert Forbidden();
        }
        if (msg.value < minRedeemValue) {
            revert LimitUnderflow(minRedeemValue, msg.value);
        }
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

    function pushRedeemBatch(uint256 batchId, bytes calldata options, bytes calldata extraOptions) external payable {
        Request storage redeem_ = _redeems[batchId];
        if (redeem_.status != Status.OPEN) {
            revert InvalidStatus();
        }
        if (redeem_.requested == 0) {
            revert Forbidden();
        }
        uint256 redeemValue = redeem_.value + msg.value;
        if (redeemValue < minPushRedeemBatchValue) {
            revert LimitUnderflow(minPushRedeemBatchValue, redeemValue);
        }
        redeemBatches++;
        redeem_.status = Status.PENDING;
        redeem_.value = 0;
        _sendMessage(
            IAdapter.MessageType.REDEEM, abi.encode(batchId, redeem_.requested), options, extraOptions, redeemValue
        );
    }

    function retryPushRedeemBatch(uint256 batchId, bytes calldata options, bytes calldata extraOptions)
        external
        payable
    {
        Request storage redeem_ = _redeems[batchId];
        if (redeem_.status != Status.PENDING) {
            revert InvalidStatus();
        }
        if (redeem_.requested == 0) {
            revert Forbidden();
        }
        if (block.timestamp < pushRedeemsTimestamp[batchId] + pushDelay) {
            revert Forbidden();
        }
        uint256 redeemValue = msg.value;
        if (redeemValue < minPushDepositBatchValue) {
            revert LimitUnderflow(minPushDepositBatchValue, redeemValue);
        }
        pushRedeemsTimestamp[batchId] = block.timestamp;
        _sendMessage(
            IAdapter.MessageType.RETRY_REDEEM,
            abi.encode(batchId, redeem_.requested),
            options,
            extraOptions,
            redeemValue
        );
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

    function claimableRedeemsOf(address user, uint256[] calldata batchIds) external view returns (uint256 assets) {
        for (uint256 i = 0; i < batchIds.length; i++) {
            Request storage redeem_ = _redeems[batchIds[i]];
            if (redeem_.status != Status.COMPLETED) {
                continue;
            }
            uint256 accountRequest = redeem_.accountRequest[user];
            if (accountRequest == 0) {
                continue;
            }
            uint256 due = Math.mulDiv(redeem_.processed, redeem_.requested, accountRequest);
            uint256 claimed = redeem_.accountClaimed[user];
            if (claimed >= due) {
                continue;
            }
            uint256 leftover = due - claimed;
            assets += leftover;
        }
    }

    function __init_SourceCore(
        address burner_,
        uint256 limit_,
        bool depositWhitelistStatus_,
        bool depositPause_,
        bool redeemPause_,
        uint256 pushDelay_
    ) internal onlyInitializing {
        burner = burner_;
        limit = limit_;
        isDepositWhitelist = depositWhitelistStatus_;
        depositPause = depositPause_;
        redeemPause = redeemPause_;
        pushDelay = pushDelay_;
    }
}
