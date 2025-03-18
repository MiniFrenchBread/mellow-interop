// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import {IMellowOFT} from "../oft/IMellowOFT.sol";
import {
    AccessControlEnumerableUpgradeable,
    IAccessControlEnumerable
} from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/**
 * @title ITargetCoreStorage
 * @dev Interface that defines the core storage layout for the TargetCore contract.
 *
 * This contract defines key storage variables, initialization parameters, and role-based access logic.
 */
interface ITargetCoreStorage is IAccessControlEnumerable {
    /**
     * @notice Structure containing initialization parameters for TargetCore.
     * @param admin Admin address with primary control over key functions.
     * @param vault Address of the vault contract for asset management.
     * @param claimer Address assigned to claim rewards or funds.
     * @param sourceEndpointId Identifier for the source endpoint in LayerZero.
     * @param sourceCoreAddress Address of the SourceCore contract.
     * @param depositRoleHolder Address assigned to the `TARGET_CORE:DEPOSIT_ROLE`.
     * @param redeemRoleHolder Address assigned to the `TARGET_CORE:REDEEM_ROLE`.
     * @param claimRoleHolder Address assigned to the `TARGET_CORE:CLAIM_ROLE`.
     * @param pushRoleHolder Address assigned to the `TARGET_CORE:PUSH_ROLE`.
     */
    struct InitParams {
        address admin;
        address vault;
        address claimer;
        uint32 sourceEndpointId;
        bytes32 sourceCoreAddress;
        address depositRoleHolder;
        address redeemRoleHolder;
        address claimRoleHolder;
        address pushRoleHolder;
    }

    /**
     * @notice Structure containing core TargetCore storage references.
     * @param oft Instance of the MellowOFT contract.
     * @param vault Instance of the ERC4626 vault contract for asset management.
     * @param claimer Address that processes claim requests.
     * @param sourceEndpointId Identifier for the source endpoint in LayerZero.
     * @param sourceCoreAddress Address of the SourceCore contract.
     */
    struct TargetStorage {
        IMellowOFT oft;
        IERC4626 vault;
        address claimer;
        uint32 sourceEndpointId;
        bytes32 sourceCoreAddress;
    }

    /**
     * @notice Role identifier for authorized deposit operations.
     */
    function DEPOSIT_ROLE() external view returns (bytes32);

    /**
     * @notice Role identifier for authorized redemption operations.
     */
    function REDEEM_ROLE() external view returns (bytes32);

    /**
     * @notice Role identifier for authorized claim operations.
     */
    function CLAIM_ROLE() external view returns (bytes32);

    /**
     * @notice Role identifier for authorized push operations (sending assets back to the source chain).
     */
    function PUSH_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the MellowOFT contract instance.
     */
    function oft() external view returns (IMellowOFT);

    /**
     * @notice Returns the ERC4626 vault contract instance.
     */
    function vault() external view returns (IERC4626);

    /**
     * @notice Returns the address assigned to process claim requests.
     */
    function claimer() external view returns (address);

    /**
     * @notice Returns the source endpoint identifier in LayerZero.
     */
    function sourceEndpointId() external view returns (uint32);

    /**
     * @notice Returns the address of the SourceCore contract.
     */
    function sourceCoreAddress() external view returns (bytes32);

    /**
     * @notice Emitted when the TargetCore storage is initialized.
     * @param params The initialization parameters.
     */
    event TargetCoreStorageInit(InitParams params);
}
