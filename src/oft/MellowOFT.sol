// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {OFT} from "@layerzerolabs/oft-evm/contracts/OFT.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @notice OFT is an ERC-20 token that extends the OFTCore contract.
contract MellowOFT is OFT {
    constructor(string memory name_, string memory symbol_, address lzEndpoint_, address delegate_)
        OFT(name_, symbol_, lzEndpoint_, delegate_)
        Ownable(delegate_)
    {}

    function removeDust(uint256 amountLD_) public view returns (uint256) {
        return (amountLD_ / decimalConversionRate) * decimalConversionRate;
    }
}
