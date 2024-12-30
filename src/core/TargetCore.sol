// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../utils/RedeemClaimer.sol";
import "./Core.sol";
import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract TargetCore is Core {
    using SafeERC20 for IERC20;

    address public immutable vault;
    address public immutable vaultClaimer;

    mapping(uint256 batchId => address claimer) public claimers;

    constructor(address owner_, address vault_, address claimer_, string memory name_, string memory symbol_)
        Core(owner_, name_, symbol_)
    {
        vault = vault_;
        vaultClaimer = claimer_;
    }

    function _receiveMessage(uint256 value, bytes memory data) internal virtual override {
        (MessageType messageType, uint256 batchId, uint256 assets, uint256 shares) =
            abi.decode(data, (MessageType, uint256, uint256, uint256));
        if (messageType == MessageType.DEPOSIT) {
            asset.mint(address(this), assets);
            IERC20(asset).safeIncreaseAllowance(vault, assets);
            IERC4626(vault).deposit(assets, address(this));
            _sendMessage(value, abi.encode(MessageType.DEPOSIT, batchId, assets));
        } else if (messageType == MessageType.REDEEM) {
            RedeemClaimer claimer = new RedeemClaimer(vaultClaimer, address(this));
            claimers[batchId] = address(claimer);
            IERC4626(vault).redeem(shares, address(claimer), address(this));
            _claim(batchId, value);
        } else {
            revert("TargetCore: INVALID_MESSAGE_TYPE");
        }
    }

    function _claim(uint256 batchId, uint256 value) internal returns (uint256 assets) {
        
    }

    function claim(uint256 batchId) external payable returns (uint256 assets) {
        return _claim(batchId, msg.value);
    }
}
