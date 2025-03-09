// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {MellowOFTAdapter} from "../oft/MellowOFTAdapter.sol";
import {SourceCoreStorage} from "./SourceCoreStorage.sol";
import {
    MessagingFee, MessagingReceipt, OFTReceipt, SendParam
} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract SourceCore is SourceCoreStorage {
    using SafeERC20 for IERC20;

    uint256 public constant D18 = 1 ether;

    constructor() {
        _disableInitializers();
    }

    modifier handleEpoch() {
        withdrawalQueue().handleEpoch();
        _;
    }

    function totalAssets() public view override returns (uint256) {
        return Math.mulDiv(totalSupply(), oracle().getValue(), D18);
    }

    function initialize(InitParams calldata params) external initializer {
        __SourceCoreStorage_init(params);
    }

    function deposit(uint256 assets, address receiver) public override nonReentrant handleEpoch returns (uint256) {
        return super.deposit(assets, receiver);
    }

    function mint(uint256 shares, address receiver) public override nonReentrant handleEpoch returns (uint256) {
        return super.mint(shares, receiver);
    }

    function requestWithdrawal(uint256 shares) external nonReentrant handleEpoch {
        if (shares == 0) {
            revert("SourceCore: zero shares");
        }
        address caller = _msgSender();
        _transfer(caller, address(withdrawalQueue()), shares);
        withdrawalQueue().request(caller, shares);
        emit WithdrawalRequested(caller, shares);
    }

    function pushToTarget() public payable nonReentrant handleEpoch onlyRole(PUSH_ROLE) returns (uint256 assets) {
        IERC20 asset_ = IERC20(asset());
        uint256 liquid = asset_.balanceOf(address(this));
        uint256 pendingShares = withdrawalQueue().totalShares();
        if (pendingShares != 0) {
            uint256 pending = Math.mulDiv(totalAssets(), pendingShares, totalSupply());
            if (pending >= liquid) {
                return 0;
            }
            liquid -= pending;
        }
        MellowOFTAdapter adapter_ = oftAdapter();
        assets = adapter_.removeDust(liquid);
        if (assets == 0) {
            return 0;
        }
        asset_.safeIncreaseAllowance(address(adapter_), assets);
        (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt) = adapter_.send{value: msg.value}(
            SendParam(targetEndpointId(), targetCoreAddress(), assets, assets, new bytes(0), new bytes(0), new bytes(0)),
            MessagingFee(msg.value, 0),
            _msgSender()
        );
        asset_.forceApprove(address(adapter_), 0);
        emit PushToTarget(assets, msgReceipt, oftReceipt);
    }

    function pull(uint256 shares, uint256 assets) external {
        address caller = _msgSender();
        if (caller != address(withdrawalQueue())) {
            revert("SourceCore: only withdrawalQueue can pull");
        }
        _burn(caller, shares);
        IERC20(asset()).safeTransfer(caller, assets);
        emit Pull(caller, shares, assets);
    }

    function _withdraw(address, address, address, uint256, uint256) internal pure override {
        revert("SourceCore: not implemented");
    }

    event WithdrawalRequested(address indexed caller, uint256 indexed shares);

    event PushToTarget(uint256 indexed assets, MessagingReceipt msgReceipt, OFTReceipt oftReceipt);

    event Pull(address indexed caller, uint256 indexed shares, uint256 indexed assets);
}
