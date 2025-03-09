// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../interfaces/utils/IWithdrawalQueue.sol";

contract WithdrawalQueue is IWithdrawalQueue, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @inheritdoc IWithdrawalQueue
    bytes32 public constant SET_WITHDRAWAL_DELAY_ROLE = keccak256("WITHDRAWAL_QUEUE:SET_WITHDRAWAL_DELAY_ROLE");

    /// @inheritdoc IWithdrawalQueue
    ISourceCore public immutable sourceCore;
    /// @inheritdoc IWithdrawalQueue
    IERC20 public immutable asset;
    /// @inheritdoc IWithdrawalQueue
    uint256 public immutable epochDuration;
    /// @inheritdoc IWithdrawalQueue
    uint256 public immutable initTimestamp;

    /// @inheritdoc IWithdrawalQueue
    uint256 public epochIterator = 0;
    /// @inheritdoc IWithdrawalQueue
    uint256 public withdrawalDelay = 1 weeks;

    /// @inheritdoc IWithdrawalQueue
    mapping(uint256 epoch => mapping(address account => uint256 shares)) public sharesOf;
    /// @inheritdoc IWithdrawalQueue
    mapping(uint256 epoch => uint256) public withdrawals;
    /// @inheritdoc IWithdrawalQueue
    mapping(uint256 epoch => uint256) public shares;

    /// @inheritdoc IWithdrawalQueue
    uint256 public totalShares;

    modifier onlyRole(bytes32 role) {
        if (!sourceCore.hasRole(role, msg.sender)) {
            revert("WithdrawalQueue: forbidden");
        }
        _;
    }

    constructor(uint256 epochDuration_, address asset_) {
        sourceCore = ISourceCore(msg.sender);
        asset = IERC20(asset_);
        epochDuration = epochDuration_;
        initTimestamp = block.timestamp;
    }

    /// @inheritdoc IWithdrawalQueue
    function setWithdrawalDelay(uint256 withdrawalDelay_) external onlyRole(SET_WITHDRAWAL_DELAY_ROLE) {
        withdrawalDelay = withdrawalDelay_;
        emit WithdrawalDelaySet(withdrawalDelay_);
    }

    /// @inheritdoc IWithdrawalQueue
    function request(address account, uint256 shares_) external nonReentrant {
        if (msg.sender != address(sourceCore)) {
            revert("WithdrawalQueue: forbidden");
        }
        handleEpoch();
        uint256 epoch = currentEpoch();
        totalShares += shares_;
        shares[epoch] += shares_;
        sharesOf[epoch][account] += shares_;
        emit Request(epoch, account, shares_);
    }

    /// @inheritdoc IWithdrawalQueue
    function claim(uint256 epoch, address receiver) external nonReentrant returns (uint256 assets) {
        handleEpoch();
        if (epoch >= epochIterator) {
            return 0;
        }
        address account = msg.sender;
        uint256 shares_ = sharesOf[epoch][account];
        if (shares_ == 0) {
            return 0;
        }
        delete sharesOf[epoch][account];
        assets = Math.mulDiv(shares_, withdrawals[epoch], shares[epoch]);
        if (assets == 0) {
            return 0;
        }
        withdrawals[epoch] -= assets;
        shares[epoch] -= shares_;
        asset.safeTransfer(receiver, assets);
        emit Claim(epoch, account, assets);
    }

    /// @inheritdoc IWithdrawalQueue
    function handleEpoch() public {
        uint256 epochIterator_ = epochIterator;
        uint256 currentEpoch_ = currentEpoch();
        if (epochIterator_ == currentEpoch_) {
            return;
        }
        if (initTimestamp + (epochIterator_ + 1) * epochDuration + withdrawalDelay > block.timestamp) {
            return;
        }

        uint256 shares_ = shares[epochIterator_];
        if (shares_ == 0) {
            epochIterator = epochIterator_ + 1;
            return;
        }

        uint256 required = sourceCore.previewRedeem(shares_);
        uint256 liquid = asset.balanceOf(address(sourceCore));
        if (liquid == 0 || required > liquid) {
            return;
        }
        sourceCore.pull(shares_, required);
        totalShares -= shares_;

        withdrawals[epochIterator_] = required;
        epochIterator = epochIterator_ + 1;
        emit HandleEpoch(epochIterator_, shares_, required);
    }

    /// @inheritdoc IWithdrawalQueue
    function currentEpoch() public view returns (uint256) {
        return (block.timestamp - initTimestamp) / epochDuration;
    }
}
