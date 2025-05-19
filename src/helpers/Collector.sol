// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../core/SourceCore.sol";

contract Collector {
    struct Request {
        uint256 epoch;
        uint256 shares;
        uint256 assets;
        bool isPending;
        uint256 claimableAt;
    }

    function collectWithdrawalRequests(address core, address account) public view returns (Request[] memory r) {
        return collectWithdrawalRequests(core, account, 256);
    }

    function estimateWithdraw(address core, uint256 shares)
        public
        view
        returns (uint256 expectedAssets, uint256 expectedTimestamp)
    {
        IWithdrawalQueue q = SourceCore(core).withdrawalQueue();
        uint256 epochs = q.currentEpoch();
        expectedTimestamp = q.initTimestamp() + (epochs + 1) * q.epochDuration() + q.withdrawalDelay();
        expectedAssets = Math.mulDiv(SourceCore(core).oracle().value(), shares, 1 ether);
    }

    function collectWithdrawalRequests(address core, address account, uint256 maxResponse)
        public
        view
        returns (Request[] memory r)
    {
        IWithdrawalQueue q = SourceCore(core).withdrawalQueue();
        uint256 epochs = q.currentEpoch();
        uint256 iterator = q.epochIterator();
        r = new Request[](maxResponse);
        uint256 index = 0;
        for (uint256 epoch = 0; epoch < iterator && index < maxResponse; epoch++) {
            uint256 shares = q.sharesOf(epoch, account);
            if (shares == 0) {
                continue;
            }
            uint256 assets = Math.mulDiv(shares, q.withdrawals(epoch), q.shares(epoch));
            r[index++] = Request({epoch: epoch, shares: shares, assets: assets, isPending: false, claimableAt: 0});
        }
        uint256 oracleValue = SourceCore(core).oracle().value();
        uint256 withdrawalDelay = q.withdrawalDelay();
        uint256 initTimestamp = q.initTimestamp();
        uint256 epochDuration = q.epochDuration();
        for (uint256 epoch = iterator; epoch <= epochs && index < maxResponse; epoch++) {
            uint256 shares = q.sharesOf(epoch, account);
            if (shares == 0) {
                continue;
            }
            uint256 assets = Math.mulDiv(shares, oracleValue, 1 ether);
            r[index++] = Request({
                epoch: epoch,
                shares: shares,
                assets: assets,
                isPending: true,
                claimableAt: initTimestamp + (epoch + 1) * epochDuration + withdrawalDelay
            });
        }
        assembly {
            mstore(r, index)
        }
    }
}
