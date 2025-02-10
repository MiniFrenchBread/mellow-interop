// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import "./ICore.sol";

interface ISourceCore is ICore {
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
        Status status;
        mapping(address account => uint256) accountRequested;
        mapping(address account => uint256) accountClaimed;
    }

    struct InitParams {
        address admin;
        address burner;
        uint256 limit;
        bool depositWhitelistStatus;
        bool depositPause;
        bool redeemPause;
        address adapter;
        address underlyingAsset;
        string name;
        string symbol;
    }

    function PAUSE_ROLE() external view returns (bytes32);

    function underlyingAsset() external view returns (IERC20);

    function burner() external view returns (address);

    function minDepositValue() external view returns (uint256);

    function minRedeemValue() external view returns (uint256);

    function limit() external view returns (uint256);

    function isDepositWhitelist() external view returns (bool);

    function depositorWhitelistStatus(address account) external view returns (bool);

    function depositPause() external view returns (bool);

    function redeemPause() external view returns (bool);

    function depositBatches() external view returns (uint256);

    function pushDepositsTimestamp(uint256 batchId) external view returns (uint256);

    function getDepositBatchInfo(uint256 batchId, address account)
        external
        view
        returns (
            uint256 value,
            uint256 totalRequested,
            uint256 totalProcessed,
            Status status,
            uint256 accountRequested,
            uint256 accountClaimed
        );

    function redeemBatches() external view returns (uint256);

    function pushRedeemsTimestamp(uint256 batchId) external view returns (uint256);

    function getRedeemBatchInfo(uint256 batchId, address account)
        external
        view
        returns (
            uint256 value,
            uint256 totalRequested,
            uint256 totalProcessed,
            Status status,
            uint256 accountRequested,
            uint256 accountClaimed
        );

    function isClaimCompleted(uint256 batchId, uint256 index) external view returns (bool);

    function isSlashingCompleted(uint256 index) external view returns (bool);

    function initialize(InitParams calldata params) external;

    function setBurner(address burner_) external;

    function setLimit(uint256 newLimit) external;

    function setDepositWhitelist(bool status) external;

    function setDepositorWhitelistStatus(address account, bool status) external;

    function setDepositPause(bool status) external;

    function setRedeemPause(bool status) external;

    function setMinDepositValue(uint256 minDepositValue_) external;

    function setMinRedeemValue(uint256 minRedeemValue_) external;

    function deposit(uint256 assets, address receiver) external payable returns (uint256 batchId);

    function pushDepositBatch(uint256 batchId) external payable;

    function retryPushDepositBatch(uint256 batchId) external payable;

    function claimDeposits(uint256[] calldata batchIds, address recipient) external returns (uint256 shares);

    function claimableDepositsOf(address user, uint256[] calldata batchIds) external view returns (uint256 assets);

    function redeem(uint256 shares, address receiver) external payable returns (uint256 batchId);

    function pushRedeemBatch(uint256 batchId) external payable;

    function retryPushRedeemBatch(uint256 batchId) external payable;

    function claimRedeems(uint256[] calldata batchIds, address recipient) external returns (uint256 assets);

    function claimableRedeemsOf(address user, uint256[] calldata batchIds) external view returns (uint256 assets);

    event BurnerSet(address indexed burner);

    event LimitSet(uint256 newLimit);

    event DepositWhitelistSet(bool status);

    event DepositorWhitelistStatusSet(address indexed account, bool status);

    event DepositPauseSet(bool status);

    event RedeemPauseSet(bool status);

    event MinDepositValueSet(uint256 minDepositValue);

    event MinRedeemValueSet(uint256 minRedeemValue);

    event Deposit(address indexed sender, address indexed receiver, uint256 indexed batchId, uint256 value);

    event DepositBatchPushed(uint256 indexed batchId);

    event DepositBatchRetryPushed(uint256 indexed batchId);

    event DepositsClaimed(uint256[] indexed batchIds, address indexed recipient, uint256 shares);

    event Redeem(address indexed sender, address indexed receiver, uint256 indexed batchId, uint256 value);

    event RedeemBatchPushed(uint256 indexed batchId);

    event RedeemBatchRetried(uint256 indexed batchId);

    event RedeemsClaimed(uint256[] indexed batchIds, address indexed recipient, uint256 assets);
}
