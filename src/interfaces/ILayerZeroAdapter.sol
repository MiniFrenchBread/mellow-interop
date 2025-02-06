// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "./IAdapter.sol";
import {MessagingFee} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import "@layerzerolabs/oft-evm/contracts/OFT.sol";
import "@layerzerolabs/oft-evm/contracts/OFTAdapter.sol";
import {SendParam} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

interface ILayerZeroAdapter is IAdapter {
    error Forbidden();
    error LimitUnderflow();
    error ForbiddenExecutor(address executor);

    function dstEid() external view returns (uint32);

    event Sent(uint32 indexed dstEid, bytes message, bytes options, MessagingReceipt receipt);
}
