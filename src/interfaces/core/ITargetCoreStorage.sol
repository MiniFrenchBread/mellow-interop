// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import {IMellowOFT} from "../oft/IMellowOFT.sol";
import {
    AccessControlEnumerableUpgradeable,
    IAccessControlEnumerable
} from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

interface ITargetCoreStorage is IAccessControlEnumerable {
    struct InitParams {
        address admin;
        string name;
        string symbol;
        address vault;
        address claimer;
        uint32 sourceEndpointId;
        bytes32 sourceCoreAddress;
        address depositRoleHolder;
        address redeemRoleHolder;
        address claimRoleHolder;
        address pushRoleHolder;
    }

    struct TargetStorage {
        IMellowOFT oft;
        IERC4626 vault;
        address claimer;
        uint32 sourceEndpointId;
        bytes32 sourceCoreAddress;
    }

    function DEPOSIT_ROLE() external view returns (bytes32);

    function REDEEM_ROLE() external view returns (bytes32);

    function CLAIM_ROLE() external view returns (bytes32);

    function PUSH_ROLE() external view returns (bytes32);

    function oft() external view returns (IMellowOFT);

    function vault() external view returns (IERC4626);

    function claimer() external view returns (address);

    function sourceEndpointId() external view returns (uint32);

    function sourceCoreAddress() external view returns (bytes32);

    event TargetCoreStorageInit(InitParams params);
}
