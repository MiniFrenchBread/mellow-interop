// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../core/SourceCore.sol";
import {ILayerZeroEndpointV2, IOAppCore} from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppCore.sol";

contract SourceHelper {
    function getNonces(SourceCore core) public view returns (uint256 inboundNonce, uint256 outboundNonce) {
        address oftAdapter = address(core.oftAdapter());
        ILayerZeroEndpointV2 endpoint = IOAppCore(oftAdapter).endpoint();
        uint32 targetEid = core.targetEndpointId();
        bytes32 oft = IOAppCore(oftAdapter).peers(targetEid);
        inboundNonce = endpoint.inboundNonce(oftAdapter, targetEid, oft);
        outboundNonce = endpoint.outboundNonce(oftAdapter, targetEid, oft);
    }

    function getSourceValue(SourceCore core) public view returns (uint256) {
        return IERC20(core.asset()).balanceOf(address(core));
    }

    function getWithdrawalData(SourceCore core) public view returns (uint256 withdrawalDemand, uint256 totalSupply) {
        withdrawalDemand = core.withdrawalQueue().totalShares();
        totalSupply = core.totalSupply();
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
