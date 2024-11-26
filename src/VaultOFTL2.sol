// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.25;

import {LockBoxL2} from "./LockBoxL2.sol";
import "./interfaces/LayerZeroImports.sol";

contract VaultOFTL2 is OFT {
    using SafeERC20 for IERC20;
    using OFTMsgCodec for bytes;
    using OFTMsgCodec for bytes32;

    /**
     * @notice Emits when batch of deposits made on L1
     * @param guid GUID of the OFT message.
     * @param srcEid Source Endpoint ID.
     * @param toAddress Address of the recipient on the dst chain.
     * @param amountReceivedLD Amount of tokens received in local decimals.
     * @param batchId Id of received batch
     */
    event OFTReceivedBatch(
        bytes32 indexed guid,
        uint32 srcEid,
        address indexed toAddress,
        uint256 amountReceivedLD,
        bytes32 indexed batchId
    );

    event OFTDepositFailed(bytes32 indexed batchId);

    uint32 public immutable dstEid;
    address public immutable transmitter;
    address public immutable underlying;
    LockBoxL2 public immutable lockBoxL2;

    constructor(address owner, LayerZeroData memory lzData)
        Ownable(owner)
        OFT(lzData.name, lzData.symbol, lzData.endpoint, owner)
    {
        transmitter = lzData.transmitter;
        underlying = lzData.underlying;
        dstEid = lzData.dstEid;
        lzData.vaultOFTL2 = address(this);
        lockBoxL2 = new LockBoxL2(owner, lzData);
    }

    /**
     * @dev Overridden default OFT method to receive message and operate with pending deposits
     * @dev Internal function to handle the receive on the LayerZero endpoint.
     * @param _origin The origin information.
     *  - srcEid: The source chain endpoint ID.
     *  - sender: The sender address from the src chain.
     *  - nonce: The nonce of the LayerZero message.
     * @param _guid The unique identifier for the received LayerZero message.
     * @param _message The encoded message. May contain batchId related to waiting deposits.
     * @dev _executor The address of the executor.
     * @dev _extraData Additional data.
     */
    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address, /*_executor*/ // @dev unused in the default implementation.
        bytes calldata /*_extraData*/ // @dev unused in the default implementation.
    ) internal virtual override {
        /// @dev The src sending chain doesn't know the address length on this chain (potentially non-evm)
        // Thus everything is bytes32() encoded in flight.
        address toAddress = _message.sendTo().bytes32ToAddress();

        uint256 amountLD = _toLD(_message.amountSD());
        uint256 amountReceivedLD;
        if (toAddress == address(this)) {
            /// @dev receive batch messages only from Ethereum minenet
            // https://docs.layerzero.network/v1/developers/evm/technical-reference/mainnet/mainnet-addresses
            require(_origin.srcEid == dstEid, "forbidden chain");
            require(_origin.sender.bytes32ToAddress() == transmitter, "forbidden sender");
            /// @dev received a batch of deposits from L1, so check attached msg
            /// @dev Credit the amountLD to this and distribute it among batch users
            require(_message.isComposed(), "msg has no batchId");
            require(_message.composeMsg().length == 64, "wrong msg length");

            /// @dev unpack batchId
            (bytes32 batchId, uint256 lpAmount) =
                abi.decode(_message.composeMsg(), (bytes32, uint256));

            if (lpAmount > 0) {
                /// @dev gives amountReceivedLD to lockBoxL2
                amountReceivedLD = _credit(address(lockBoxL2), amountLD, _origin.srcEid);
                /// @dev lockBoxL2 distributes amountReceivedLD among batch depositors
                lockBoxL2.distributeDeposit(batchId, amountReceivedLD);
                emit OFTReceivedBatch(
                    _guid, _origin.srcEid, address(this), amountReceivedLD, batchId
                );
            } else {
                /// @dev dummy distribution with zero amount => set waiting batch as failed
                lockBoxL2.distributeDeposit(batchId, 0);
            }
        } else {
            /// @dev regular cross-chain transfer
            amountReceivedLD = _credit(toAddress, amountLD, _origin.srcEid);
            emit OFTReceived(_guid, _origin.srcEid, toAddress, amountReceivedLD);
        }
    }
}
