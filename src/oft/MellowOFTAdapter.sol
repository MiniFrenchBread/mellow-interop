// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import {OFTAdapter} from "@layerzerolabs/oft-evm/contracts/OFTAdapter.sol";
import {
    MessagingFee, MessagingReceipt, OFTReceipt, SendParam
} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MellowOFTAdapter is OFTAdapter {
    address public sourceCore;

    constructor(address token_, address lzEndpoint_, address owner_)
        OFTAdapter(token_, lzEndpoint_, owner_)
        Ownable(owner_)
    {}

    function initialize(address sourceCore_) external {
        if (sourceCore != address(0)) {
            revert("MellowOFTAdapter: already initialized");
        }
        if (sourceCore_ == address(0)) {
            revert("MellowOFTAdapter: zero address");
        }
        sourceCore = sourceCore_;
    }

    function removeDust(uint256 amountLD_) public view returns (uint256) {
        return _removeDust(amountLD_);
    }

    function send(SendParam calldata sendParam_, MessagingFee calldata fee_, address refundAddress_)
        external
        payable
        override
        returns (MessagingReceipt memory, OFTReceipt memory)
    {
        if (_msgSender() != sourceCore) {
            revert("MellowOFTAdapter: forbidden");
        }
        return _send(sendParam_, fee_, refundAddress_);
    }
}
