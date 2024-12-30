// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import {MessagingFee} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import "@layerzerolabs/oft-evm/contracts/OFT.sol";
import "@layerzerolabs/oft-evm/contracts/OFTAdapter.sol";
import {SendParam} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./IAdapter.sol";

contract LayerZeroAdapter is OApp, OAppOptionsType3, IAdapter {
    constructor(address endpoint_, address delegate_) OApp(endpoint_, delegate_) Ownable(delegate_) {}

    struct SendCommonParams {
        uint32 dstEid;
        address refundAddress;
    }

    function send(bytes32 chainId, bytes32 sender, bytes calldata data) external payable override {
        // _lzSend(
        // uint32 _dstEid,
        // bytes memory _message,
        // bytes memory _options,
        // MessagingFee memory _fee,
        // address _refundAddress
        // ) internal virtual returns (MessagingReceipt memory receipt)
    }

    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) internal override {}
}
