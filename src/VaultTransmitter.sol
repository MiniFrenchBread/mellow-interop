// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.25;

import "./interfaces/IVault.sol";
import "./interfaces/LayerZeroImports.sol";
import {VaultOFTAdapter} from "src/VaultOFTAdapter.sol";

contract VaultTransmitter is OAppReceiver {
    using SafeERC20 for IERC20;
    using OptionsBuilder for bytes;
    using OFTMsgCodec for bytes32;
    using OFTMsgCodec for address;

    uint32 public immutable dstEid; // L2 chain id in terms of LZ
    address public immutable underlying;
    IVault public immutable vault;
    address public immutable vaultOFTL2;
    address public immutable lockBoxL2;
    address public immutable stargate;
    VaultOFTAdapter public immutable oftAdapterL1;

    address private _refundAddress;

    constructor(address owner, address _vault, LayerZeroData memory lzData)
        Ownable(owner)
        OAppCore(lzData.endpoint, owner)
    {
        dstEid = lzData.dstEid;
        stargate = lzData.stargate;
        vault = IVault(_vault);
        vaultOFTL2 = lzData.vaultOFTL2;
        lockBoxL2 = lzData.lockBoxL2;
        underlying = vault.underlying();
        oftAdapterL1 = VaultOFTAdapter(lzData.oftAdapterL1);
    }

    /**
     * @dev Receives message from `lockBoxL2` with assets and batchId
     * @dev Overridden default OFT method to receive message and operate with pending deposits
     * @dev Internal function to handle the receive on the LayerZero endpoint.
     * @param _origin The origin information.
     *  - srcEid: The source chain endpoint ID.
     *  - sender: The sender address from the src chain.
     *  - nonce: The nonce of the LayerZero message.
     * @dev _guid The unique identifier for the received LayerZero message.
     * @param _message The encoded message. May contain batchId related to waiting deposits.
     * @dev _executor The address of the executor.
     * @dev _extraData Additional data.
     */
    function _lzReceive(
        Origin calldata _origin,
        bytes32,
        bytes calldata _message,
        address, /*_executor*/ // @dev unused in the default implementation.
        bytes calldata /*_extraData*/ // @dev unused in the default implementation.
    ) internal virtual override {
        require(_origin.sender.bytes32ToAddress() == lockBoxL2, "!lockBoxL2");
        require(msg.sender == address(endpoint), "!endpoint");

        (bytes32 batchId, uint256 amountLD, uint128 length) =
            abi.decode(_message, (bytes32, uint256, uint128));

        /// @dev Push assets into the Vault and get lp tokens
        /// @dev returns zero lpAmount in case of revert
        (uint256 lpAmount) = _pushDeposit(amountLD);

        /// @dev send message via OFTAdapter in any case
        _sendMessage(batchId, lpAmount, length);
    }

    function _sendMessage(bytes32 batchId, uint256 lpAmount, uint128 length) internal {
        bytes memory extraOptions =
            OptionsBuilder.newOptions().addExecutorLzComposeOption(0, 100000 * (length + 2), 0); // gas limit on L2: receive(~50k) + (length+1) transfers (~100k)

        SendParam memory sendParam = SendParam({
            dstEid: dstEid, // Destination endpoint ID.
            to: vaultOFTL2.addressToBytes32(), // Recipient address.
            amountLD: lpAmount, // Amount to send in local decimals.
            minAmountLD: lpAmount, // Minimum amount to send in local decimals.
            extraOptions: extraOptions, // Additional options supplied by the caller to be used in the LayerZero message.
            composeMsg: abi.encode(batchId, lpAmount), // The composed message for the send() operation.
            oftCmd: "" // The OFT command to be executed, unused in default OFT implementations.
        });

        (MessagingFee memory msgFee) = oftAdapterL1.quoteSend(sendParam, false);

        /// @dev OFTAdapter takes lpAmount of underlying tokens and sends message to OFT on L2
        //(MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt) =
        oftAdapterL1.send(sendParam, msgFee, _refundAddress);

        /// @dev TBD check and emit event
    }

    function _pushDeposit(uint256 amountLD) internal returns (uint256) {
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amountLD;
        try vault.deposit(address(this), amounts, 0, type(uint256).max, 0) returns (
            uint256[] memory, uint256 lpAmount
        ) {
            return lpAmount;
        } catch {
            return 0;
        }
    }
}
