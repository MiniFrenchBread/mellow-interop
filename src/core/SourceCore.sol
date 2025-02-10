// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import "../interfaces/ISourceCore.sol";
import "./Core.sol";

contract SourceCore is ISourceCore, Core {
    using SafeERC20 for IERC20;

    /// @inheritdoc ISourceCore
    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");

    /// @inheritdoc ISourceCore
    IERC20 public underlyingAsset;
    /// @inheritdoc ISourceCore
    address public burner;

    /// @inheritdoc ISourceCore
    uint256 public minDepositValue;
    /// @inheritdoc ISourceCore
    uint256 public minRedeemValue;

    /// @inheritdoc ISourceCore
    uint256 public limit;
    /// @inheritdoc ISourceCore
    bool public isDepositWhitelist;
    /// @inheritdoc ISourceCore
    mapping(address account => bool) public depositorWhitelistStatus;
    /// @inheritdoc ISourceCore
    bool public depositPause;
    /// @inheritdoc ISourceCore
    bool public redeemPause;

    /// @inheritdoc ISourceCore
    uint256 public depositBatches;
    /// @inheritdoc ISourceCore
    mapping(uint256 batchId => uint256) public pushDepositsTimestamp;

    /// @inheritdoc ISourceCore
    uint256 public redeemBatches;
    /// @inheritdoc ISourceCore
    mapping(uint256 batchId => uint256) public pushRedeemsTimestamp;
    /// @inheritdoc ISourceCore
    mapping(uint256 batchId => mapping(uint256 index => bool)) public isClaimCompleted;
    /// @inheritdoc ISourceCore
    mapping(uint256 index => bool) public isSlashingCompleted;

    mapping(uint256 batchId => Request) private _deposits;
    mapping(uint256 batchId => Request) private _redeems;

    constructor(bytes32 name_, uint256 version_) CoreStorage(name_, version_) {
        _disableInitializers();
    }

    /// @inheritdoc ISourceCore
    function initialize(InitParams calldata params) external initializer {
        __init_Core(params.admin, params.adapter, params.name, params.symbol);
        __init_SourceCore(
            params.burner,
            params.limit,
            params.depositWhitelistStatus,
            params.depositPause,
            params.redeemPause,
            params.underlyingAsset
        );
    }

    /// @inheritdoc ISourceCore
    function setBurner(address burner_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        burner = burner_;
        emit BurnerSet(burner_);
    }

    /// @inheritdoc ISourceCore
    function setLimit(uint256 newLimit) external onlyRole(DEFAULT_ADMIN_ROLE) {
        limit = newLimit;
        emit LimitSet(newLimit);
    }

    /// @inheritdoc ISourceCore
    function setDepositWhitelist(bool status) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isDepositWhitelist = status;
        emit DepositWhitelistSet(status);
    }

    /// @inheritdoc ISourceCore
    function setDepositorWhitelistStatus(address account, bool status) external onlyRole(DEFAULT_ADMIN_ROLE) {
        depositorWhitelistStatus[account] = status;
        emit DepositorWhitelistStatusSet(account, status);
    }

    /// @inheritdoc ISourceCore
    function setDepositPause(bool status) external onlyRole(PAUSE_ROLE) {
        depositPause = status;
        emit DepositPauseSet(status);
    }

    /// @inheritdoc ISourceCore
    function setRedeemPause(bool status) external onlyRole(PAUSE_ROLE) {
        redeemPause = status;
        emit RedeemPauseSet(status);
    }

    /// @inheritdoc ISourceCore
    function setMinDepositValue(uint256 minDepositValue_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        minDepositValue = minDepositValue_;
        emit MinDepositValueSet(minDepositValue_);
    }

    /// @inheritdoc ISourceCore
    function setMinRedeemValue(uint256 minRedeemValue_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        minRedeemValue = minRedeemValue_;
        emit MinRedeemValueSet(minRedeemValue_);
    }

    /// @inheritdoc ISourceCore
    function deposit(uint256 assets, address receiver) external payable returns (uint256 batchId) {
        address sender = _msgSender();
        if (depositPause || isDepositWhitelist && !depositorWhitelistStatus[sender]) {
            revert Forbidden();
        }
        if (assets + underlyingAsset.balanceOf(address(this)) > limit) {
            revert LimitOverflow(limit, assets + underlyingAsset.balanceOf(address(this)));
        }

        if (msg.value < minDepositValue) {
            revert InsufficientValue(minDepositValue, msg.value);
        }
        underlyingAsset.safeTransferFrom(sender, address(this), assets);

        batchId = depositBatches;
        Request storage deposit_ = _deposits[batchId];
        if (deposit_.status == Status.CLOSED) {
            deposit_.status = Status.OPEN;
            deposit_.requested = assets;
            deposit_.accountRequested[receiver] = assets;
            deposit_.value = msg.value;
        } else {
            deposit_.requested += assets;
            deposit_.accountRequested[receiver] += assets;
            deposit_.value += msg.value;
        }
        emit Deposit(sender, receiver, batchId, assets);
    }

    /// @inheritdoc ISourceCore
    function pushDepositBatch(uint256 batchId) external payable {
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
        depositBatches++;
        deposit_.status = Status.PENDING;
        deposit_.value = 0;
        _sendMessage(IAdapter.MessageType.DEPOSIT, abi.encode(batchId, deposit_.requested), depositValue);
        emit DepositBatchPushed(batchId);
    }

    /// @inheritdoc ISourceCore
    function retryPushDepositBatch(uint256 batchId) external payable atLeastOperator {
        Request storage deposit_ = _deposits[batchId];
        if (deposit_.status != Status.PENDING) {
            revert InvalidStatus();
        }
        if (deposit_.requested == 0) {
            revert Forbidden();
        }
        uint256 depositValue = msg.value;
        _sendMessage(IAdapter.MessageType.DEPOSIT, abi.encode(batchId, deposit_.requested), depositValue);
    }

    /// @inheritdoc ISourceCore
    function claimDeposits(uint256[] calldata batchIds, address recipient) external returns (uint256 shares) {
        address sender = _msgSender();
        for (uint256 i = 0; i < batchIds.length; i++) {
            Request storage deposit_ = _deposits[batchIds[i]];
            if (deposit_.status != Status.COMPLETED) {
                continue;
            }
            uint256 accountRequested = deposit_.accountRequested[sender];
            if (accountRequested == 0) {
                continue;
            }
            uint256 due = Math.mulDiv(deposit_.processed, accountRequested, deposit_.requested);
            uint256 claimed = deposit_.accountClaimed[sender];
            if (claimed >= due) {
                continue;
            }
            uint256 leftover = due - claimed;
            shares += leftover;
            deposit_.accountClaimed[sender] = due;
        }
        if (shares != 0) {
            asset().mint(recipient, shares);
        }
    }

    /// @inheritdoc ISourceCore
    function redeem(uint256 shares, address receiver) external payable returns (uint256 batchId) {
        if (redeemPause) {
            revert Forbidden();
        }
        if (msg.value < minRedeemValue) {
            revert InsufficientValue(minRedeemValue, msg.value);
        }
        address sender = _msgSender();
        asset().burn(sender, shares);
        batchId = redeemBatches;
        Request storage redeem_ = _redeems[batchId];
        if (redeem_.status == Status.CLOSED) {
            redeem_.status = Status.OPEN;
            redeem_.requested = shares;
            redeem_.accountRequested[receiver] = shares;
            redeem_.value = msg.value;
        } else if (redeem_.status == Status.OPEN) {
            redeem_.requested += shares;
            redeem_.accountRequested[receiver] += shares;
            redeem_.value += msg.value;
        }
        emit Redeem(sender, receiver, batchId, shares);
    }

    /// @inheritdoc ISourceCore
    function pushRedeemBatch(uint256 batchId) external payable {
        Request storage redeem_ = _redeems[batchId];
        if (redeem_.status != Status.OPEN) {
            revert InvalidStatus();
        }
        if (batchId != 0 && _redeems[batchId - 1].status != Status.COMPLETED) {
            revert InvalidStatus();
        }
        if (redeem_.requested == 0) {
            revert Forbidden();
        }
        uint256 redeemValue = redeem_.value + msg.value;
        redeemBatches++;
        redeem_.status = Status.PENDING;
        redeem_.value = 0;
        _sendMessage(IAdapter.MessageType.REDEEM, abi.encode(batchId, redeem_.requested), redeemValue);
    }

    /// @inheritdoc ISourceCore
    function retryPushRedeemBatch(uint256 batchId) external payable atLeastOperator {
        Request storage redeem_ = _redeems[batchId];
        if (redeem_.status != Status.PENDING) {
            revert InvalidStatus();
        }
        if (redeem_.requested == 0) {
            revert Forbidden();
        }
        uint256 redeemValue = msg.value;
        _sendMessage(IAdapter.MessageType.REDEEM, abi.encode(batchId, redeem_.requested), redeemValue);
    }

    /// @inheritdoc ISourceCore
    function claimRedeems(uint256[] calldata batchIds, address recipient) external returns (uint256 assets) {
        address sender = _msgSender();
        for (uint256 i = 0; i < batchIds.length; i++) {
            Request storage redeem_ = _redeems[batchIds[i]];
            if (redeem_.status != Status.COMPLETED) {
                continue;
            }
            uint256 accountRequested = redeem_.accountRequested[sender];
            if (accountRequested == 0) {
                continue;
            }
            uint256 due = Math.mulDiv(redeem_.processed, accountRequested, redeem_.requested);
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

    /// @inheritdoc ISourceCore
    function claimableDepositsOf(address user, uint256[] calldata batchIds) external view returns (uint256 assets) {
        for (uint256 i = 0; i < batchIds.length; i++) {
            Request storage deposit_ = _deposits[batchIds[i]];
            if (deposit_.status != Status.COMPLETED) {
                continue;
            }
            uint256 accountRequested = deposit_.accountRequested[user];
            if (accountRequested == 0) {
                continue;
            }
            uint256 due = Math.mulDiv(deposit_.processed, accountRequested, deposit_.requested);
            uint256 claimed = deposit_.accountClaimed[user];
            if (claimed >= due) {
                continue;
            }
            uint256 leftover = due - claimed;
            assets += leftover;
        }
    }

    /// @inheritdoc ISourceCore
    function claimableRedeemsOf(address user, uint256[] calldata batchIds) external view returns (uint256 assets) {
        for (uint256 i = 0; i < batchIds.length; i++) {
            Request storage redeem_ = _redeems[batchIds[i]];
            if (redeem_.status != Status.COMPLETED) {
                continue;
            }
            uint256 accountRequested = redeem_.accountRequested[user];
            if (accountRequested == 0) {
                continue;
            }
            uint256 due = Math.mulDiv(redeem_.processed, accountRequested, redeem_.requested);
            uint256 claimed = redeem_.accountClaimed[user];
            if (claimed >= due) {
                continue;
            }
            uint256 leftover = due - claimed;
            assets += leftover;
        }
    }

    /// @inheritdoc ISourceCore
    function getDepositBatchInfo(uint256 batchId, address account)
        public
        view
        returns (
            uint256 value,
            uint256 totalRequested,
            uint256 totalProcessed,
            Status status,
            uint256 accountRequested,
            uint256 accountClaimed
        )
    {
        Request storage deposit_ = _deposits[batchId];
        value = deposit_.value;
        totalRequested = deposit_.requested;
        totalProcessed = deposit_.processed;
        status = deposit_.status;
        accountRequested = deposit_.accountRequested[account];
        accountClaimed = deposit_.accountClaimed[account];
    }

    /// @inheritdoc ISourceCore
    function getRedeemBatchInfo(uint256 batchId, address account)
        public
        view
        returns (
            uint256 value,
            uint256 totalRequested,
            uint256 totalProcessed,
            Status status,
            uint256 accountRequested,
            uint256 accountClaimed
        )
    {
        Request storage redeem_ = _redeems[batchId];
        value = redeem_.value;
        totalRequested = redeem_.requested;
        totalProcessed = redeem_.processed;
        status = redeem_.status;
        accountRequested = redeem_.accountRequested[account];
        accountClaimed = redeem_.accountClaimed[account];
    }

    function __init_SourceCore(
        address burner_,
        uint256 limit_,
        bool depositWhitelistStatus_,
        bool depositPause_,
        bool redeemPause_,
        address underlyingAsset_
    ) internal onlyInitializing {
        burner = burner_;
        limit = limit_;
        isDepositWhitelist = depositWhitelistStatus_;
        depositPause = depositPause_;
        redeemPause = redeemPause_;
        underlyingAsset = IERC20(underlyingAsset_);
    }

    function _receiveMessage(IAdapter.MessageType messageType, bytes calldata message) internal virtual override {
        if (messageType == IAdapter.MessageType.DEPOSIT) {
            (uint256 batchId, uint256 amount) = abi.decode(message, (uint256, uint256));
            Request storage deposit_ = _deposits[batchId];
            if (deposit_.status != Status.PENDING) {
                revert InvalidStatus();
            }
            deposit_.status = Status.COMPLETED;
            deposit_.processed = amount;
        } else if (messageType == IAdapter.MessageType.CLAIM) {
            (uint256 batchId, uint256 index, uint256 amount) = abi.decode(message, (uint256, uint256, uint256));
            Request storage redeem_ = _redeems[batchId];
            if (isClaimCompleted[batchId][index]) {
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
        } else if (messageType == IAdapter.MessageType.SLASHING) {
            (uint256 index, uint256 amount) = abi.decode(message, (uint256, uint256));
            if (isSlashingCompleted[index]) {
                return;
            }
            isSlashingCompleted[index] = true;
            underlyingAsset.safeTransfer(burner, amount);
        } else {
            revert InvalidMessageType();
        }
    }
}
