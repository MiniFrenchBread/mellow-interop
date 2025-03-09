// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import {
    ILayerZeroEndpointV2,
    Origin
} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract Delegator is AccessControlEnumerable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    ILayerZeroEndpointV2 public immutable endpointV2;

    constructor(address admin_, address operator_, address endpointV2_) {
        if (admin_ == address(0) || operator_ == address(0) || endpointV2_ == address(0)) {
            revert("Delegator: invalid parameters");
        }
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(OPERATOR_ROLE, operator_);
        endpointV2 = ILayerZeroEndpointV2(endpointV2_);
    }

    function call(address target, bytes calldata data, uint256 value)
        external
        payable
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bytes memory response)
    {
        response = Address.functionCallWithValue(target, data, value);
        emit Call(target, data, value, response);
    }

    function clear(address oapp_, Origin calldata origin_, bytes32 guid_, bytes calldata message_)
        external
        onlyRole(OPERATOR_ROLE)
    {
        endpointV2.clear(oapp_, origin_, guid_, message_);
        emit Clear(oapp_, origin_, guid_, message_);
    }

    receive() external payable {}

    event Call(address indexed target, bytes data, uint256 value, bytes response);
    event Clear(address indexed oapp, Origin origin, bytes32 guid, bytes message);
}
