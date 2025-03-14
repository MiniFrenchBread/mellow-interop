// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {IMellowOFTAdapter} from "../oft/IMellowOFTAdapter.sol";
import {IOracle} from "../utils/IOracle.sol";
import {IWithdrawalQueue} from "../utils/IWithdrawalQueue.sol";
import {
    AccessControlEnumerableUpgradeable,
    IAccessControlEnumerable
} from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import {
    ERC4626Upgradeable,
    IERC4626
} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISourceCoreStorage is IERC4626, IAccessControlEnumerable {
    struct InitParams {
        address admin;
        string name;
        string symbol;
        address mellowOFTAdapter;
        uint256 epochDuration;
        uint32 targetEndpointId;
        bytes32 targetCoreAddress;
        uint256 limit;
        address pushRoleHolder;
        address setWithdrawalDelayRoleHolder;
        address setValueRoleHolder;
        address setMaxAgeRoleHolder;
        address setLimitRoleHolder;
    }

    struct SourceStorage {
        IWithdrawalQueue withdrawalQueue;
        IMellowOFTAdapter oftAdapter;
        IOracle oracle;
        uint32 targetEndpointId;
        bytes32 targetCoreAddress;
        uint256 limit;
    }

    function D18() external view returns (uint256);

    function PUSH_ROLE() external view returns (bytes32);

    function SET_LIMIT_ROLE() external view returns (bytes32);

    function withdrawalQueue() external view returns (IWithdrawalQueue);

    function oftAdapter() external view returns (IMellowOFTAdapter);

    function oracle() external view returns (IOracle);

    function targetEndpointId() external view returns (uint32);

    function targetCoreAddress() external view returns (bytes32);

    function limit() external view returns (uint256);

    function setLimit(uint256) external;

    event LimitSet(uint256 limit);

    event SourceCoreStorageInitialized(InitParams params, IWithdrawalQueue withdrawalQueue, IOracle oracle);
}
