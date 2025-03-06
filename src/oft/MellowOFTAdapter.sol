// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import {OFTAdapter} from "@layerzerolabs/oft-evm/contracts/OFTAdapter.sol";
import {
    MessagingFee, MessagingReceipt, OFTReceipt, SendParam
} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MellowOFTAdapter is OFTAdapter {
    address public immutable sourceCore;

    constructor(address sourceCore_, address token_, address lzEndpoint_, address owner_)
        OFTAdapter(token_, lzEndpoint_, owner_)
        Ownable(owner_)
    {
        sourceCore = sourceCore_;
    }

    function removeDust(uint256 amountLD_) public view returns (uint256) {
        return (amountLD_ / decimalConversionRate) * decimalConversionRate;
    }

    function send(SendParam calldata sendParam_, MessagingFee calldata fee_, address refundAddress_)
        external
        payable
        override
        returns (MessagingReceipt memory, OFTReceipt memory)
    {
        if (_msgSender() != sourceCore) {
            revert("Forbidden");
        }
        return _send(sendParam_, fee_, refundAddress_);
    }
}
