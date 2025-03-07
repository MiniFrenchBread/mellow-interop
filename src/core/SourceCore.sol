// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {SourceCoreStorage} from "./SourceCoreStorage.sol";
import {MessagingFee, SendParam} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
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
        require(shares > 0, "SourceCore: zero shares");
        address caller = _msgSender();
        _transfer(caller, address(withdrawalQueue()), shares);
        withdrawalQueue().request(caller, shares);
    }

    function pushToTarget() public payable nonReentrant handleEpoch onlyRole(PUSH_ROLE) returns (uint256 assets) {
        uint256 liquid = IERC20(asset()).balanceOf(address(this));
        uint256 pending = Math.mulDiv(totalAssets(), withdrawalQueue().totalShares(), totalSupply());
        if (pending >= liquid) {
            return 0;
        }
        assets = oftAdapter().removeDust(liquid - pending);
        if (assets == 0) {
            return 0;
        }
        oftAdapter().send{value: msg.value}(
            SendParam(targetEndpointId(), targetCoreAddress(), assets, assets, new bytes(0), new bytes(0), new bytes(0)),
            MessagingFee(msg.value, 0),
            _msgSender()
        );
    }

    function pull(uint256 shares, uint256 assets) external {
        address caller = _msgSender();
        require(caller == address(withdrawalQueue()), "SourceCore: only withdrawalQueue can pull");
        _burn(caller, shares);
        IERC20(asset()).safeTransfer(caller, assets);
    }

    function _withdraw(address, address, address, uint256, uint256) internal pure override {
        revert("SourceCore: not implemented");
    }
}
