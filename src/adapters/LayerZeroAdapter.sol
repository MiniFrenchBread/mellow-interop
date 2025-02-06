// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../interfaces/ILayerZeroAdapter.sol";

contract LayerZeroAdapter is OApp, OAppOptionsType3, ILayerZeroAdapter {
    error InvalidParams();

    /// @inheritdoc IAdapter
    ICore public immutable core;
    /// @inheritdoc ILayerZeroAdapter
    uint32 public immutable dstEid;

    /// @inheritdoc IAdapter
    address public gasReceiver;
    /// @inheritdoc ILayerZeroAdapter
    bool public isExecutorWhitelist;
    /// @inheritdoc ILayerZeroAdapter
    mapping(address executor => bool) public executorWhitelistStatus;

    constructor(address endpoint_, address delegate_, address core_, uint32 dstEid_, address gasReceiver_)
        OApp(endpoint_, delegate_)
        Ownable(delegate_)
    {
        if (address(core_) == address(0)) {
            revert InvalidParams();
        }
        if (dstEid_ == 0) {
            revert InvalidParams();
        }
        if (address(gasReceiver_) == address(0)) {
            revert InvalidParams();
        }
        core = ICore(core_);
        dstEid = dstEid_;
        gasReceiver = gasReceiver_;
    }

    /// @inheritdoc ILayerZeroAdapter
    function setIsExecutorWhitelist(bool status) external onlyOwner {
        isExecutorWhitelist = status;
    }

    /// @inheritdoc ILayerZeroAdapter
    function setExecutorWhitelistStatus(address executor, bool status) external onlyOwner {
        executorWhitelistStatus[executor] = status;
    }

    /// @inheritdoc ILayerZeroAdapter
    function setGasReceiver(address gasReceiver_) external onlyOwner {
        if (gasReceiver_ == address(0)) {
            revert InvalidParams();
        }
        gasReceiver = gasReceiver_;
    }

    /// @inheritdoc IAdapter
    function encodeMessage(MessageType messageType, bytes calldata message) public pure returns (bytes memory) {
        return abi.encode(messageType, message);
    }

    /// @inheritdoc IAdapter
    function decodeMessage(bytes calldata fullMessage)
        public
        pure
        returns (MessageType messageType, bytes memory message)
    {
        (messageType, message) = abi.decode(fullMessage, (MessageType, bytes));
    }

    /// @inheritdoc IAdapter
    function quoteMessage(MessageType messageType, bytes calldata message, bytes calldata options)
        public
        view
        returns (uint256 nativeFee)
    {
        if (options.length != 0) {
            revert InvalidOptions(options);
        }
        bytes memory options_ = combineOptions(dstEid, uint16(uint256(messageType)), options);
        return _quote(dstEid, message, options_, false).nativeFee;
    }

    /// @inheritdoc IAdapter
    function sendMessage(MessageType messageType, bytes calldata message, bytes calldata options)
        external
        payable
        override
    {
        if (msg.sender != address(core)) {
            revert Forbidden();
        }
        if (options.length != 0) {
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
        address executor,
        bytes calldata /* _extraData */
    ) internal override {
        if (isExecutorWhitelist && !executorWhitelistStatus[executor]) {
            revert Forbidden();
        }
        (MessageType messageType, bytes memory message) = decodeMessage(_message);
        ICore(core).receiveMessage{value: msg.value}(messageType, message);
    }
}
