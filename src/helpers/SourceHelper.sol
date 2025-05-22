// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../core/SourceCore.sol";
import {ILayerZeroEndpointV2, IOAppCore} from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppCore.sol";

contract SourceHelper {
    function getNonces(SourceCore core) public view returns (uint256 inboundNonce, uint256 outboundNonce) {
        ILayerZeroEndpointV2 endpoint = IOAppCore(address(core.oftAdapter())).endpoint();
        uint32 targetEid = core.targetEndpointId();
        bytes32 targetCore = core.targetCoreAddress();
        inboundNonce = endpoint.inboundNonce(address(core), targetEid, targetCore);
        outboundNonce = endpoint.outboundNonce(address(core), targetEid, targetCore);
    }

    function getAmounts(SourceCore core) public view returns (uint256 pullAssets, uint256 pushAssets) {
        uint256 redeemDemand = core.previewRedeem(core.withdrawalQueue().totalShares());
        uint256 liquidAssets = IERC20(core.asset()).balanceOf(address(core));
        if (liquidAssets < redeemDemand) {
            pullAssets = core.oftAdapter().removeDust(redeemDemand - liquidAssets);
        } else {
            pushAssets = core.oftAdapter().removeDust(liquidAssets - redeemDemand);
        }
    }

    function quotePushToTarget(SourceCore core) public view returns (uint256) {
        return core.oftAdapter().quoteSend(
            SendParam({
                dstEid: core.targetEndpointId(),
                to: core.targetCoreAddress(),
                amountLD: 1 ether,
                minAmountLD: 0,
                extraOptions: new bytes(0),
                composeMsg: new bytes(0),
                oftCmd: new bytes(0)
            }),
            false
        ).nativeFee;
    }
}
