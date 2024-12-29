// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

// import "./Imports.sol";
// import "./OwnedERC20.sol";

// abstract contract BaseCore is OApp, OAppOptionsType3 {
//     // Action statuses:
//     // CLOSED   actions are not yet allowed
//     // OPEN     actions are allowed
//     // PENDING  actions are no longer allowed, but are being processed
//     // SUCCESS  actions are no longer allowed, but can be claimed
//     // FAILED   actions are no longer allowed, and cannot be claimed. Waiting for next retry
//     enum Status {
//         CLOSED,
//         OPEN,
//         PENDING,
//         SUCCESS,
//         FAILED
//     }

//     struct Request {
//         uint256 totalRequested;
//         uint256 totalProcessed;
//         mapping(address account => uint256) requests;
//         mapping(address account => uint256) claimed;
//         Status status;
//     }

//     mapping(uint256 batchId => Request) internal _deposits;
//     mapping(uint256 batchId => Request) internal _withdrawals;

//     uint256 public depositBatches;
//     uint256 public withdrawBatches;

//     OwnedERC20 public immutable asset;

//     function deposits(uint256 batchId, address account)
//         external
//         view
//         returns (uint256 totalRequested, uint256 totalProcessed, uint256 requets, uint256 claimed, Status status)
//     {
//         Request storage request = _deposits[batchId];
//         return (
//             request.totalRequested,
//             request.totalProcessed,
//             request.requests[account],
//             request.claimed[account],
//             request.status
//         );
//     }

//     function withdrawals(uint256 batchId, address account)
//         external
//         view
//         returns (uint256 totalRequested, uint256 totalProcessed, uint256 requets, uint256 claimed, Status status)
//     {
//         Request storage request = _withdrawals[batchId];
//         return (
//             request.totalRequested,
//             request.totalProcessed,
//             request.requests[account],
//             request.claimed[account],
//             request.status
//         );
//     }

//     constructor(string memory name_, string memory symbol_) {
//         asset = new OwnedERC20(name_, symbol_, address(this));
//     }
// }
