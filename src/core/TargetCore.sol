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
    mapping(uint256 batchId => address) public claimers;

    constructor(address owner_, address vault_, address claimer_, string memory name_, string memory symbol_)
        Core(owner_, name_, symbol_)
    {
        vault = vault_;
        vaultClaimer = claimer_;
    }

    function setSlasher(address slasher_) external onlyOwner {
        /// @dev vault, separate slasher contract or zero address
        slasher = slasher_;
    }

    function _receiveMessage(IAdapter.MessageType messageType, bytes calldata message, bytes calldata extraOptions)
        internal
        virtual
        override
    {
        (uint256 batchId, uint256 amount) = abi.decode(message, (uint256, uint256));
        if (messageType == IAdapter.MessageType.DEPOSIT) {
            asset.mint(address(this), amount);
            IERC20(asset).safeIncreaseAllowance(vault, amount);
            uint256 shares = IERC4626(vault).deposit(amount, address(this));
            _sendMessage(
                IAdapter.MessageType.DEPOSIT, abi.encode(batchId, shares), extraOptions, new bytes(0), msg.value
            );
        } else if (messageType == IAdapter.MessageType.REDEEM) {
            RedeemClaimer claimer = new RedeemClaimer(vaultClaimer, address(this));
            claimers[batchId] = address(claimer);
            IERC4626(vault).redeem(amount, address(claimer), address(this));
        } else {
            revert("TargetCore: INVALID_MESSAGE_TYPE");
        }
    }

    // NOTE: permissionless claim
    function claim(uint256 batchId, bytes calldata data, bytes calldata options)
        external
        payable
        returns (uint256 assets)
    {
        RedeemClaimer claimer = RedeemClaimer(claimers[batchId]);
        require(address(claimer) != address(0), "TargetCore: INVALID_CLAIMER");
        assets = claimer.claim(vault, data);
        _sendMessage(IAdapter.MessageType.CLAIM, abi.encode(batchId, assets), options, new bytes(0), msg.value);
    }

    function onSlash(uint256 assets, bytes calldata options) external payable {
        require(msg.sender == slasher, "TargetCore: INVALID_SLASHER");
        _sendMessage(IAdapter.MessageType.SLASHING, abi.encode(0, assets), options, new bytes(0), msg.value);
    }
}
