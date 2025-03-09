// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../interfaces/oft/IMellowOFTAdapter.sol";

contract MellowOFTAdapter is IMellowOFTAdapter, OFTAdapter {
    /// @inheritdoc IMellowOFTAdapter
    address public sourceCore;

    constructor(address token_, address lzEndpoint_, address owner_)
        OFTAdapter(token_, lzEndpoint_, owner_)
        Ownable(owner_)
    {}

    /// @inheritdoc IMellowOFTAdapter
    function initialize(address sourceCore_) external {
        if (sourceCore != address(0)) {
            revert("MellowOFTAdapter: already initialized");
        }
        if (sourceCore_ == address(0)) {
            revert("MellowOFTAdapter: zero address");
        }
        sourceCore = sourceCore_;
    }

    /// @inheritdoc IMellowOFTAdapter
    function removeDust(uint256 amountLD_) public view returns (uint256) {
        return _removeDust(amountLD_);
    }

    /// @inheritdoc IOFT
    function send(SendParam calldata sendParam_, MessagingFee calldata fee_, address refundAddress_)
        external
        payable
        override(IOFT, OFTCore)
        returns (MessagingReceipt memory, OFTReceipt memory)
    {
        if (_msgSender() != sourceCore) {
            revert("MellowOFTAdapter: forbidden");
        }
        return _send(sendParam_, fee_, refundAddress_);
    }
}
