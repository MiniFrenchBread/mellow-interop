// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import {
    ILayerZeroEndpointV2,
    Origin
} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

interface IDelegator {
    function OPERATOR_ROLE() external view returns (bytes32);

    function endpointV2() external view returns (ILayerZeroEndpointV2);

    function call(address target, bytes calldata data, uint256 value)
        external
        payable
        returns (bytes memory response);

    function clear(address oapp_, Origin calldata origin_, bytes32 guid_, bytes calldata message_) external;

    event Call(address indexed target, bytes data, uint256 value, bytes response);
    event Clear(address indexed oapp, Origin origin, bytes32 guid, bytes message);
}
