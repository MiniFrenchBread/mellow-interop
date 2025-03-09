// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import {OFTAdapter, OFTCore} from "@layerzerolabs/oft-evm/contracts/OFTAdapter.sol";
import {
    IOFT,
    MessagingFee,
    MessagingReceipt,
    OFTReceipt,
    SendParam
} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IMellowOFTAdapter is IOFT {
    function sourceCore() external view returns (address);

    function initialize(address sourceCore_) external;

    function removeDust(uint256 amountLD_) external view returns (uint256);
}
