// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import {MellowOFT} from "../oft/MellowOFT.sol";
import {MessagingFee, SendParam} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract TargetCore is AccessControlEnumerable {
    using SafeERC20 for IERC20;

    bytes32 public constant DEPOSIT_ROLE = keccak256("TARGET_CORE:DEPOSIT_ROLE");
    bytes32 public constant REDEEM_ROLE = keccak256("TARGET_CORE:REDEEM_ROLE");
    bytes32 public constant CLAIM_ROLE = keccak256("TARGET_CORE:CLAIM_ROLE");
    bytes32 public constant PUSH_ROLE = keccak256("TARGET_CORE:PUSH_ROLE");

    MellowOFT public immutable oft;
    IERC4626 public immutable vault;
    address public immutable claimer;

    uint32 public sourceEndpointId;
    bytes32 public sourceCoreAddress;

    constructor(
        address admin_,
        address delegate_,
        string memory name_,
        string memory symbol_,
        address lzEndpoint_,
        address vault_,
        address claimer_
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        oft = new MellowOFT(name_, symbol_, lzEndpoint_, delegate_);
        vault = IERC4626(vault_);
        claimer = claimer_;
    }

    function initialize(
        uint32 sourceEndpointId_,
        bytes32 sourceCoreAddress_,
        address depositRoleHolder_,
        address redeemRoleHolder_,
        address claimRoleHolder_,
        address pushRoleHoler_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (sourceCoreAddress != bytes32(0)) {
            revert("TargetCore: already initialized");
        }
        if (sourceCoreAddress_ == bytes32(0)) {
            revert("TargetCore: zero address");
        }
        if (vault.asset() != address(oft)) {
            revert("TargetCore: invalid vault asset");
        }
        sourceEndpointId = sourceEndpointId_;
        sourceCoreAddress = sourceCoreAddress_;

        if (depositRoleHolder_ != address(0)) {
            _grantRole(DEPOSIT_ROLE, depositRoleHolder_);
        }

        if (redeemRoleHolder_ != address(0)) {
            _grantRole(REDEEM_ROLE, redeemRoleHolder_);
        }

        if (claimRoleHolder_ != address(0)) {
            _grantRole(CLAIM_ROLE, claimRoleHolder_);
        }

        if (pushRoleHoler_ != address(0)) {
            _grantRole(PUSH_ROLE, pushRoleHoler_);
        }
    }

    function deposit(uint256 assets) external onlyRole(DEPOSIT_ROLE) {
        IERC20(oft).safeIncreaseAllowance(address(vault), assets);
        vault.deposit(assets, address(this));
        IERC20(oft).forceApprove(address(vault), 0);
    }

    function redeem(uint256 shares) external onlyRole(REDEEM_ROLE) {
        vault.redeem(shares, address(this), address(this));
    }

    function claim(bytes calldata data) external onlyRole(CLAIM_ROLE) {
        uint256 balanceBefore = oft.balanceOf(address(this));
        bytes memory response = Address.functionCall(claimer, data);
        require(response.length == 32, "TargetCore: invalid response");
        uint256 expectedAssets = abi.decode(response, (uint256));
        uint256 balanceAfter = oft.balanceOf(address(this));
        require(expectedAssets > 0 && balanceAfter == balanceBefore + expectedAssets, "TargetCore: claim failed");
    }

    function pushToSource(uint256 assets, bytes calldata data) external payable onlyRole(PUSH_ROLE) {
        assets = oft.removeDust(assets);
        uint256 liquid = oft.balanceOf(address(this));
        if (assets < liquid) {
            revert("TargetCore: insufficient assets");
        }
        if (assets == 0) {
            return;
        }
        oft.send{value: msg.value}(
            SendParam(sourceEndpointId, sourceCoreAddress, assets, assets, new bytes(0), new bytes(0), new bytes(0)),
            MessagingFee(msg.value, 0),
            _msgSender()
        );
    }
}
