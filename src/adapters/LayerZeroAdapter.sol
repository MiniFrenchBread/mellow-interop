// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../interfaces/ILayerZeroAdapter.sol";

contract LayerZeroAdapter is OApp, OAppOptionsType3, ILayerZeroAdapter {
    ICore public core;
    uint32 public dstEid;
    address public gasReceiver;

    constructor(address endpoint_, address delegate_) OApp(endpoint_, delegate_) Ownable(delegate_) {}

    function setCore(address core_) external onlyOwner {
        require(address(core) == address(0), "LayerZeroAdapter: core already set");
        core = ICore(core_);
    }

    function setDstEid(uint32 eid) external onlyOwner {
        require(dstEid == 0, "LayerZeroAdapter: dstEid already set");
        dstEid = eid;
    }

    function setGasReceiver(address receiver) external onlyOwner {
        gasReceiver = receiver;
    }

    function encodeMessage(MessageType messageType, bytes calldata message) public pure returns (bytes memory) {
        return abi.encode(messageType, message);
    }

    function decodeMessage(bytes calldata fullMessage)
        public
        pure
        returns (MessageType messageType, bytes memory message)
    {
        (messageType, message) = abi.decode(fullMessage, (MessageType, bytes));
    }

    function quoteMessage(MessageType messageType, bytes calldata message, bytes calldata options)
        public
        view
        returns (uint256 nativeFee)
    {
        if (options.length != 0) {
            // only forced options are allowed
            revert InvalidOptions(options);
        }
        bytes memory options_ = combineOptions(dstEid, uint16(uint256(messageType)), options);
        return _quote(dstEid, message, options_, false).nativeFee;
    }

    function sendMessage(MessageType messageType, bytes calldata message, bytes calldata options)
        external
        payable
        override
    {
        if (msg.sender != address(core)) {
            revert Forbidden();
        }
        if (options.length != 0) {
            // only forced options are allowed
            revert InvalidOptions(options);
        }

        bytes memory options_ = combineOptions(dstEid, uint16(uint256(messageType)), options);

        MessagingReceipt memory receipt = _lzSend(dstEid, message, options_, MessagingFee(msg.value, 0), gasReceiver);

        emit Sent(dstEid, message, options_, receipt);
    }

    function _lzReceive(
        Origin calldata, /* _origin */
        bytes32, /* _guid */
        bytes calldata _message,
        address, /* _executor */
        bytes calldata /* _extraData */
    ) internal override {
        (MessageType messageType, bytes memory message) = decodeMessage(_message);
        ICore(core).receiveMessage{value: msg.value}(messageType, message);
    }
}
