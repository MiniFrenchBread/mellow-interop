// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../interfaces/utils/IDelegator.sol";

contract Delegator is IDelegator, AccessControlEnumerable {
    /// @inheritdoc IDelegator
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /// @inheritdoc IDelegator
    ILayerZeroEndpointV2 public immutable endpointV2;

    constructor(address admin_, address operator_, address endpointV2_) {
        if (admin_ == address(0) || operator_ == address(0) || endpointV2_ == address(0)) {
            revert("Delegator: invalid parameters");
        }
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(OPERATOR_ROLE, operator_);
        endpointV2 = ILayerZeroEndpointV2(endpointV2_);
    }

    /// @inheritdoc IDelegator
    function call(address target, bytes calldata data, uint256 value)
        external
        payable
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bytes memory response)
    {
        response = Address.functionCallWithValue(target, data, value);
        emit Call(target, data, value, response);
    }

    /// @inheritdoc IDelegator
    function clear(address oapp_, Origin calldata origin_, bytes32 guid_, bytes calldata message_)
        external
        onlyRole(OPERATOR_ROLE)
    {
        endpointV2.clear(oapp_, origin_, guid_, message_);
        emit Clear(oapp_, origin_, guid_, message_);
    }

    receive() external payable {}
}
