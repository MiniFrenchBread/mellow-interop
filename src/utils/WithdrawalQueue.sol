// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../core/SourceCore.sol";

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract WithdrawalQueue is ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public constant SET_WITHDRAWAL_DELAY_ROLE = keccak256("WITHDRAWAL_QUEUE:SET_WITHDRAWAL_DELAY_ROLE");

    SourceCore public immutable sourceCore;
    IERC20 public immutable asset;
    uint256 public immutable epochDuration;
    uint256 public immutable initTimestamp;

    uint256 public epochIterator = 0;
    uint256 public withdrawalDelay = 1 weeks;

    mapping(uint256 epoch => mapping(address account => uint256 shares)) public sharesOf;
    mapping(uint256 epoch => uint256) public withdrawals;
    mapping(uint256 epoch => uint256) public shares;

    uint256 public totalShares;

    modifier onlyRole(bytes32 role) {
        require(sourceCore.hasRole(role, msg.sender), "WithdrawalQueue: forbidden");
        _;
    }

    constructor(uint256 epochDuration_, address asset_) {
        sourceCore = SourceCore(msg.sender);
        asset = IERC20(asset_);
        epochDuration = epochDuration_;
        initTimestamp = block.timestamp;
    }

    function setWithdrawalDelay(uint256 withdrawalDelay_) external onlyRole(SET_WITHDRAWAL_DELAY_ROLE) {
        withdrawalDelay = withdrawalDelay_;
    }

    function request(address account, uint256 shares_) external nonReentrant {
        require(msg.sender == address(sourceCore), "Forbidden");
        handleEpoch();
        uint256 epoch = currentEpoch();
        totalShares += shares_;
        shares[epoch] += shares_;
        sharesOf[epoch][account] += shares_;
    }

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
    }

    function handleEpoch() public {
        uint256 epochIterator_ = epochIterator;
        uint256 currentEpoch_ = currentEpoch();
        if (epochIterator_ == currentEpoch_) {
            return;
        }
        if (initTimestamp + (epochIterator_ + 2) * epochDuration + withdrawalDelay < block.timestamp) {
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
    }

    function currentEpoch() public view returns (uint256) {
        return (block.timestamp - initTimestamp) / epochDuration;
    }
}
