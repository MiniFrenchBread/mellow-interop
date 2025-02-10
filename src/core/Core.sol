// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../interfaces/ICore.sol";
import "./CoreStorage.sol";

abstract contract Core is ICore, CoreStorage, AccessControlEnumerableUpgradeable {
    /// @inheritdoc ICore
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /// @inheritdoc ICore
    function setAdapter(address adapter_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setAdapter(adapter_);
    }

    /// @inheritdoc ICore
    function receiveMessage(IAdapter.MessageType messageType, bytes calldata message) external payable virtual {
        if (_msgSender() != address(adapter())) {
            revert Forbidden();
        }
        emit MessageReceived(messageType, message, msg.value);
        _receiveMessage(messageType, message);
    }

    function _receiveMessage(IAdapter.MessageType messageType, bytes calldata message) internal virtual;

    function _sendMessage(IAdapter.MessageType messageType, bytes memory message, uint256 value) internal {
        IAdapter adapter_ = adapter();
        bytes memory fullMessage = adapter_.encodeMessage(messageType, message);
        uint256 requiredValue = adapter_.quoteMessage(messageType, fullMessage, new bytes(0));

        if (requiredValue > value) {
            revert InsufficientValue(requiredValue, value);
        }

        adapter_.sendMessage{value: requiredValue}(messageType, fullMessage, new bytes(0));
        if (requiredValue < value) {
            Address.sendValue(payable(adapter_.gasReceiver()), value - requiredValue);
        }
        emit MessageSent(messageType, message, requiredValue);
    }

    function __init_Core(address admin_, address adapter_, string memory name_, string memory symbol_)
        internal
        onlyInitializing
    {
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _setAdapter(adapter_);
        address asset_ = address(new OwnedERC20(name_, symbol_, address(this)));
        _setAsset(asset_);
    }
}
