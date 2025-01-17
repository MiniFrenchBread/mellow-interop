// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../interfaces/ILayerZeroAdapter.sol";

contract LayerZeroAdapter is OApp, OAppOptionsType3, ILayerZeroAdapter {
    ICore public immutable core;
    uint32 public immutable dstEid;

    constructor(address endpoint_, address delegate_, address core_, uint32 dstEid_)
        OApp(endpoint_, delegate_)
        Ownable(delegate_)
    {
        core = ICore(core_);
        dstEid = dstEid_;
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
        MessagingReceipt memory receipt = _lzSend(
            dstEid, encodeMessage(messageType, message, extraOptions), options_, fee, Ownable(msg.sender).owner()
        );

        emit Sent(dstEid, message, options_, extraOptions, receipt);
    }

    function _lzReceive(
        Origin calldata, /* _origin */
        bytes32, /* _guid */
        bytes calldata _message,
        address, /* _executor */
        bytes calldata /* _extraData */
    ) internal override {
        (MessageType messageType, bytes memory message, bytes memory extraOptions) = decodeMessage(_message);
        ICore(core).receiveMessage(messageType, message, extraOptions);
    }
}
