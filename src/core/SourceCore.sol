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

    constructor(bytes32 name_, uint256 version_) CoreStorage(name_, version_) {}

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
    }

    /// @inheritdoc ISourceCore
    function setLimit(uint256 newLimit) external onlyRole(DEFAULT_ADMIN_ROLE) {
        limit = newLimit;
    }

    /// @inheritdoc ISourceCore
    function setDepositWhitelist(bool status) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isDepositWhitelist = status;
    }

    /// @inheritdoc ISourceCore
    function setDepositorWhitelistStatus(address account, bool status) external onlyRole(DEFAULT_ADMIN_ROLE) {
        depositorWhitelistStatus[account] = status;
    }

    /// @inheritdoc ISourceCore
    function setDepositPause(bool status) external onlyRole(PAUSE_ROLE) {
        depositPause = status;
    }

    /// @inheritdoc ISourceCore
    function setRedeemPause(bool status) external onlyRole(PAUSE_ROLE) {
        redeemPause = status;
    }

    /// @inheritdoc ISourceCore
    function setMinDepositValue(uint256 minDepositValue_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        minDepositValue = minDepositValue_;
    }

    /// @inheritdoc ISourceCore
    function setMinRedeemValue(uint256 minRedeemValue_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        minRedeemValue = minRedeemValue_;
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

    /// @inheritdoc ISourceCore
    function deposit(uint256 assets, address receiver) external payable returns (uint256 batchId) {
        if (depositPause || isDepositWhitelist && !depositorWhitelistStatus[_msgSender()]) {
            revert Forbidden();
        }
        if (assets + underlyingAsset.balanceOf(address(this)) > limit) {
            revert LimitOverflow(limit, assets + underlyingAsset.balanceOf(address(this)));
        }

        if (msg.value < minDepositValue) {
            revert LimitUnderflow(minDepositValue, msg.value);
        }
        underlyingAsset.safeTransferFrom(_msgSender(), address(this), assets);

        batchId = depositBatches;
        Request storage deposit_ = _deposits[batchId];
        if (deposit_.status == Status.CLOSED) {
            deposit_.status = Status.OPEN;
            deposit_.requested = assets;
            deposit_.accountRequest[receiver] = assets;
            deposit_.value = msg.value;
        } else {
            deposit_.requested += assets;
            deposit_.accountRequest[receiver] += assets;
            deposit_.value += msg.value;
        }
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
    }

    /// @inheritdoc ISourceCore
    function retryPushDepositBatch(uint256 batchId) external payable onlyRole(OPERATOR_ROLE) {
        Request storage deposit_ = _deposits[batchId];
        if (deposit_.status != Status.PENDING) {
            revert InvalidStatus();
        }
        if (deposit_.requested == 0) {
            revert Forbidden();
        }
        uint256 depositValue = msg.value;
        _sendMessage(IAdapter.MessageType.RETRY_DEPOSIT, abi.encode(batchId, deposit_.requested), depositValue);
    }

    /// @inheritdoc ISourceCore
    function claimDeposits(uint256[] calldata batchIds, address recipient) external returns (uint256 shares) {
        address sender = _msgSender();
        for (uint256 i = 0; i < batchIds.length; i++) {
            Request storage deposit_ = _deposits[batchIds[i]];
            if (deposit_.status != Status.COMPLETED) {
                continue;
            }
            uint256 accountRequest = deposit_.accountRequest[sender];
            if (accountRequest == 0) {
                continue;
            }
            uint256 due = Math.mulDiv(deposit_.processed, accountRequest, deposit_.requested);
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
    function claimableDepositsOf(address user, uint256[] calldata batchIds) external view returns (uint256 assets) {
        for (uint256 i = 0; i < batchIds.length; i++) {
            Request storage deposit_ = _deposits[batchIds[i]];
            if (deposit_.status != Status.COMPLETED) {
                continue;
            }
            uint256 accountRequest = deposit_.accountRequest[user];
            if (accountRequest == 0) {
                continue;
            }
            uint256 due = Math.mulDiv(deposit_.processed, accountRequest, deposit_.requested);
            uint256 claimed = deposit_.accountClaimed[user];
            if (claimed >= due) {
                continue;
            }
            uint256 leftover = due - claimed;
            assets += leftover;
        }
    }

    /// @inheritdoc ISourceCore
    function redeem(uint256 shares, address receiver) external payable returns (uint256 batchId) {
        if (redeemPause) {
            revert Forbidden();
        }
        if (msg.value < minRedeemValue) {
            revert LimitUnderflow(minRedeemValue, msg.value);
        }
        asset().burn(_msgSender(), shares);
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
        }
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
    function retryPushRedeemBatch(uint256 batchId) external payable onlyRole(OPERATOR_ROLE) {
        Request storage redeem_ = _redeems[batchId];
        if (redeem_.status != Status.PENDING) {
            revert InvalidStatus();
        }
        if (redeem_.requested == 0) {
            revert Forbidden();
        }
        uint256 redeemValue = msg.value;
        _sendMessage(IAdapter.MessageType.RETRY_REDEEM, abi.encode(batchId, redeem_.requested), redeemValue);
    }

    /// @inheritdoc ISourceCore
    function claimRedeems(uint256[] calldata batchIds, address recipient) external returns (uint256 assets) {
        address sender = _msgSender();
        for (uint256 i = 0; i < batchIds.length; i++) {
            Request storage redeem_ = _redeems[batchIds[i]];
            if (redeem_.status != Status.COMPLETED) {
                continue;
            }
            uint256 accountRequest = redeem_.accountRequest[sender];
            if (accountRequest == 0) {
                continue;
            }
            uint256 due = Math.mulDiv(redeem_.processed, accountRequest, redeem_.requested);
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
            uint256 due = Math.mulDiv(redeem_.processed, accountRequest, redeem_.requested);
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
        address underlyingAsset_
    ) internal onlyInitializing {
        burner = burner_;
        limit = limit_;
        isDepositWhitelist = depositWhitelistStatus_;
        depositPause = depositPause_;
        redeemPause = redeemPause_;
        underlyingAsset = IERC20(underlyingAsset_);
    }
}
