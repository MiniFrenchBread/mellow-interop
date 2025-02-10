// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../utils/RedeemClaimer.sol";
import "./ICore.sol";

interface ITargetCore is ICore {
    function BURNER_ROLE() external view returns (bytes32);

    function vault() external view returns (address);

    function redeemClaimerSingleton() external view returns (RedeemClaimer);

    function redeemClaimers(uint256 batchId) external view returns (address);

    function isDepositBatchCompleted(uint256 batchId) external view returns (bool);

    function depositBatchShares(uint256 batchId) external view returns (uint256);

    function depositBatchValues(uint256 batchId) external view returns (uint256);

    function isRedeemBatchCompleted(uint256 batchId) external view returns (bool);

    function claimsCount(uint256 batchId) external view returns (uint256);

    function claims(uint256 batchId, uint256 index) external view returns (uint256);

    function slashingEvents(uint256 index) external view returns (uint256);

    function slashings() external view returns (uint256);

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

    function pushDeposit(uint256 batchId) external payable;

    function slash(uint256 assets) external payable;

    function retrySlash(uint256 index) external payable;

    event Claim(uint256 indexed batchId, uint256 indexed index, uint256 assets);

    event ClaimRetried(uint256 indexed batchId, uint256 indexed index, uint256 assets);

    event DepositBatchPushed(uint256 indexed batchId, uint256 shares, uint256 value);

    event Slashing(uint256 indexed index, uint256 assets);

    event SlashingRetried(uint256 indexed index, uint256 assets);
}
