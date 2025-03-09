// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import "../interfaces/oft/IMellowOFT.sol";

contract MellowOFT is IMellowOFT, OFT {
    constructor(string memory name_, string memory symbol_, address lzEndpoint_, address delegate_)
        OFT(name_, symbol_, lzEndpoint_, delegate_)
        Ownable(delegate_)
    {}

    /// @inheritdoc IMellowOFT
    function removeDust(uint256 amountLD_) public view returns (uint256) {
        return _removeDust(amountLD_);
    }
}
