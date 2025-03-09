// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {OFT} from "@layerzerolabs/oft-evm/contracts/OFT.sol";
import {IOFT} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMellowOFT is IOFT, IERC20 {
    function removeDust(uint256 amountLD_) external view returns (uint256);
}
