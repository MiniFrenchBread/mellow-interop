// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../interfaces/ILayerZeroAdapter.sol";

contract LayerZeroAdapter is OApp, OAppOptionsType3, ILayerZeroAdapter {
    ICore public immutable core;
    uint32 public immutable dstEid;

    address public gasReceiver;
    bool public isExecutorWhitelist;
    mapping(address executor => bool) public executorWhitelistStatus;

    constructor(address endpoint_, address delegate_, address core_, uint32 dstEid_, address gasReceiver_)
        OApp(endpoint_, delegate_)
        Ownable(delegate_)
    {
        core = ICore(core_);
        dstEid = dstEid_;
        gasReceiver = gasReceiver_;
    }

    function setExecutorWhitelist(bool status) external onlyOwner {
        isExecutorWhitelist = status;
    }

    function setExecutorWhitelistStatus(address executor, bool status) external onlyOwner {
        executorWhitelistStatus[executor] = status;
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
            revert ForbiddenExecutor(executor);
        }
        (MessageType messageType, bytes memory message) = decodeMessage(_message);
        ICore(core).receiveMessage{value: msg.value}(messageType, message);
    }
}
