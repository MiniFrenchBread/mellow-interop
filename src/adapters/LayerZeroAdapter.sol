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

import "../interfaces/IAdapter.sol";

contract LayerZeroAdapter is OApp, OAppOptionsType3, IAdapter {
    error Forbidden();
    error LimitUnderflow();

    ICore public immutable core;
    uint32 public immutable dstEid;
    address public dstAdapter;

    constructor(address endpoint_, address delegate_, address core_) OApp(endpoint_, delegate_) Ownable(delegate_) {
        core = ICore(core_);
    }

    function setDestinationAdapter(address adapter) external onlyOwner {
        dstAdapter = adapter;
    }

    function encodeMessage(MessageType messageType, bytes calldata message, bytes calldata extraOptions)
        public
        pure
        returns (bytes memory)
    {
        return abi.encode(messageType, message, extraOptions);
    }

    function decodeMessage(bytes calldata message) public pure returns (MessageType, bytes memory, bytes memory) {
        return abi.decode(message, (MessageType, bytes, bytes));
    }

    function sendMessage(
        MessageType messageType,
        bytes calldata message,
        bytes calldata options,
        bytes calldata extraOptions
    ) external payable override {
        if (msg.sender != address(core)) {
            revert Forbidden();
        }

        bytes memory options_ = combineOptions(dstEid, uint16(uint256(messageType)), options);

        MessagingFee memory fee = _quote(dstEid, message, options_, false);

        if (fee.nativeFee > msg.value) {
            revert LimitUnderflow();
        }
        MessagingReceipt memory receipt =
            _lzSend(dstEid, encodeMessage(messageType, message, extraOptions), options_, fee, msg.sender);

        emit Sent(dstEid, message, options_, extraOptions, receipt);
    }

    function _lzReceive(
        Origin calldata _origin,
        bytes32, /* _guid */
        bytes calldata _message,
        address, /* _executor */
        bytes calldata /* _extraData */
    ) internal override {
        if (_origin.srcEid != dstEid) {
            revert Forbidden();
        }
        if (_origin.sender != bytes32(uint256(uint160(dstAdapter)))) {
            revert Forbidden();
        }

        (MessageType messageType, bytes memory message, bytes memory extraOptions) = decodeMessage(_message);
        ICore(core).receiveMessage(messageType, message, extraOptions);
    }

    event Sent(uint32 indexed dstEid, bytes message, bytes options, bytes extraOptions, MessagingReceipt receipt);
}
