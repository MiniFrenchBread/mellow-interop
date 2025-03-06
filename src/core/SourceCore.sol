// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {MellowOFTAdapter} from "../oft/MellowOFTAdapter.sol";
import {Oracle} from "../utils/Oracle.sol";
import {WithdrawalQueue} from "../utils/WithdrawalQueue.sol";

import {MessagingFee, SendParam} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {ERC20, ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract SourceCore is ERC4626, AccessControlEnumerable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant D18 = 1 ether;

    bytes32 public constant PUSH_ROLE = keccak256("SOURCE_CORE:PUSH_ROLE");

    WithdrawalQueue public immutable withdrawalQueue;
    MellowOFTAdapter public immutable oftAdapter;
    Oracle public immutable oracle;

    uint32 public targetEndpointId;
    bytes32 public targetCoreAddress;

    modifier handleEpoch() {
        withdrawalQueue.handleEpoch();
        _;
    }

    constructor(
        address asset_,
        string memory name_,
        string memory symbol_,
        address admin_,
        address delegate_,
        uint256 epochDuration_,
        address lzEndpoint_
    ) ERC4626(IERC20(asset_)) ERC20(name_, symbol_) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        withdrawalQueue = new WithdrawalQueue(epochDuration_, asset_);
        oftAdapter = new MellowOFTAdapter(address(this), asset_, lzEndpoint_, delegate_);
        oracle = new Oracle(address(this));
    }

    /// --------------------------------------------------------------
    /// ----------------- EXTERNAL VIEW FUNCTIONS -----------------
    /// --------------------------------------------------------------

    function totalAssets() public view override returns (uint256) {
        return Math.mulDiv(totalSupply(), oracle.getValue(), D18);
    }

    /// --------------------------------------------------------------
    /// ----------------- EXTERNAL MUTABLE FUNCTIONS -----------------
    /// --------------------------------------------------------------

    function initialize(
        uint32 targetEndpointId_,
        bytes32 targetCoreAddress_,
        address pushRoleHolder_,
        address setWithdrawalDelayRoleHoler_,
        address setValueRoleHoler_,
        address setMaxAgeRoleHoler_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (targetCoreAddress != bytes32(0)) {
            revert("SourceCore: target parameters already set");
        }
        if (targetCoreAddress_ == bytes32(0)) {
            revert("SourceCore: targetCoreAddress cannot be zero");
        }
        targetEndpointId = targetEndpointId_;
        targetCoreAddress = targetCoreAddress_;

        if (pushRoleHolder_ != address(0)) {
            _grantRole(PUSH_ROLE, pushRoleHolder_);
        }

        if (setWithdrawalDelayRoleHoler_ != address(0)) {
            _grantRole(withdrawalQueue.SET_WITHDRAWAL_DELAY_ROLE(), setWithdrawalDelayRoleHoler_);
        }

        if (setValueRoleHoler_ != address(0)) {
            _grantRole(oracle.SET_VALUE_ROLE(), setValueRoleHoler_);
        }

        if (setMaxAgeRoleHoler_ != address(0)) {
            _grantRole(oracle.SET_MAX_AGE_ROLE(), setMaxAgeRoleHoler_);
        }
    }

    function deposit(uint256 assets, address receiver) public override nonReentrant handleEpoch returns (uint256) {
        return super.deposit(assets, receiver);
    }

    function mint(uint256 shares, address receiver) public override nonReentrant handleEpoch returns (uint256) {
        return super.mint(shares, receiver);
    }

    function requestWithdrawal(uint256 shares) external nonReentrant handleEpoch {
        require(shares > 0, "SourceCore: zero shares");
        address caller = _msgSender();
        _transfer(caller, address(withdrawalQueue), shares);
        withdrawalQueue.request(caller, shares);
    }

    function pushToTarget() public payable nonReentrant handleEpoch onlyRole(PUSH_ROLE) returns (uint256 assets) {
        uint256 liquid = IERC20(asset()).balanceOf(address(this));
        uint256 pending = Math.mulDiv(totalAssets(), withdrawalQueue.totalShares(), totalSupply());
        if (pending >= liquid) {
            return 0;
        }
        assets = oftAdapter.removeDust(liquid - pending);
        if (assets == 0) {
            return 0;
        }
        oftAdapter.send{value: msg.value}(
            SendParam(targetEndpointId, targetCoreAddress, assets, assets, new bytes(0), new bytes(0), new bytes(0)),
            MessagingFee(msg.value, 0),
            _msgSender()
        );
    }

    function pull(uint256 shares, uint256 assets) external {
        address caller = _msgSender();
        require(caller == address(withdrawalQueue), "SourceCore: only withdrawalQueue can pull");
        _burn(caller, shares);
        IERC20(asset()).safeTransfer(caller, assets);
    }

    /// --------------------------------------------------------------
    /// --------------------- INTERNAL FUNCTIONS ---------------------
    /// --------------------------------------------------------------

    function _withdraw(address, address, address, uint256, uint256) internal pure override {
        revert("SourceCore: not implemented");
    }
}
