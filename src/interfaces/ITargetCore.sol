// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../utils/RedeemClaimer.sol";
import "./ICore.sol";

interface ITargetCore is ICore {
    function BURNER_ROLE() external view returns (bytes32);

    function vault() external view returns (address);

    function redeemClaimerSingleton() external view returns (RedeemClaimer);

    function redeemClaimers(uint256 batchId) external view returns (address);

    function isDepositBatchReceived(uint256 batchId) external view returns (bool);

    function depositBatchShares(uint256 batchId) external view returns (uint256);

    function depositBatchAssets(uint256 batchId) external view returns (uint256);

    function redeemBatchShares(uint256 batchId) external view returns (uint256);

    function isRedeemBatchReceived(uint256 batchId) external view returns (bool);

    function claimBatchCount(uint256 batchId) external view returns (uint256);

    function claimBatchAssets(uint256 batchId, uint256 index) external view returns (uint256);

    function slashingRequestsAt(uint256 index) external view returns (uint256);

    function slashingRequests() external view returns (uint256);

    function isDepositBatchRejected(uint256 batchId) external view returns (bool);

    function isRedeemBatchRejected(uint256 batchId) external view returns (bool);

    function initialize(
        address admin_,
        address vault_,
        address adapter_,
        address claimer_,
        string memory name_,
        string memory symbol_
    ) external;

    function claim(uint256 batchId, bytes calldata data) external payable returns (uint256 assets);

    function retryClaim(uint256 batchId, uint256 index) external payable;

    function pushDepositBatch(uint256 batchId) external payable;

    function slash(uint256 assets) external payable;

    function pushSlashing(uint256 index) external payable;

    function rejectDepositBatch(uint256 batchId) external payable;

    function retryPushDepositBatch(uint256 batchId) external payable;

    function rejectRedeemBatch(uint256 batchId) external payable;

    event RedeemBatchRejected(uint256 indexed batchId, uint256 value);

    event Claim(uint256 indexed batchId, uint256 indexed index, uint256 assets);

    event ClaimRetried(uint256 indexed batchId, uint256 indexed index, uint256 assets);

    event DepositBatchPushed(uint256 indexed batchId, uint256 shares, uint256 value);

    event DepositBatchRejected(uint256 indexed batchId, uint256 value);

    event SlashingRequested(uint256 indexed index, uint256 assets);

    event SlashingPushed(uint256 indexed index, uint256 assets);
}
