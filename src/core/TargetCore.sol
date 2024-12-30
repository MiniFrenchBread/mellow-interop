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

    address public slasher;
    uint256 public messagesSent;
    mapping(uint256 batchId => address) public claimers;
    mapping(uint256 messageId => bytes) public sentMessageById;

    constructor(address owner_, address vault_, address claimer_, string memory name_, string memory symbol_)
        Core(owner_, name_, symbol_)
    {
        vault = vault_;
        vaultClaimer = claimer_;
    }

    function setSlasher(address slasher_) external onlyOwner {
        slasher = slasher_;
    }

    function _receiveMessage(uint256 value, bytes memory data) internal virtual override {
        (MessageType messageType, uint256 batchId, uint256 assets, uint256 shares) =
            abi.decode(data, (MessageType, uint256, uint256, uint256));
        if (messageType == MessageType.DEPOSIT) {
            asset.mint(address(this), assets);
            IERC20(asset).safeIncreaseAllowance(vault, assets);
            shares = IERC4626(vault).deposit(assets, address(this));
            uint256 messageId_ = messagesSent;
            bytes memory message = abi.encode(MessageType.DEPOSIT, messageId_, batchId, assets, shares);
            _sendMessage(value, message);
            sentMessageById[messageId_] = message;
            messagesSent = messageId_ + 1;
        } else if (messageType == MessageType.REDEEM) {
            RedeemClaimer claimer = new RedeemClaimer(vaultClaimer, address(this));
            claimers[batchId] = address(claimer);
            IERC4626(vault).redeem(shares, address(claimer), address(this));
        } else {
            revert("TargetCore: INVALID_MESSAGE_TYPE");
        }
    }

    // NOTE: permissionless claim
    function claim(uint256 batchId, bytes calldata data) external payable returns (uint256 assets) {
        RedeemClaimer claimer = RedeemClaimer(claimers[batchId]);
        require(address(claimer) != address(0), "TargetCore: INVALID_CLAIMER");
        assets = claimer.claim(vault, data);
        uint256 messageId_ = messagesSent;
        bytes memory message = abi.encode(MessageType.CLAIM, messageId_, batchId, assets, 0);
        _sendMessage(msg.value, message);
        sentMessageById[messageId_] = message;
        messagesSent = messageId_ + 1;
    }

    function onSlash(uint256 assets) external {
        require(msg.sender == slasher, "TargetCore: INVALID_SLASHER");
        uint256 messageId_ = messagesSent;
        bytes memory message = abi.encode(MessageType.SLASHING, messageId_, 0, assets, 0);
        _sendMessage(msg.value, message);
        sentMessageById[messageId_] = message;
        messagesSent = messageId_ + 1;
    }
}
