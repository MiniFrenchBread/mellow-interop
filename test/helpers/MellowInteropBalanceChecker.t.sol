// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import "../Imports.sol";

contract MellowInteropBalanceCheckerTest is Test {
    address public proxyAdmin = vm.createWallet("proxy-admin").addr;
    address public admin = vm.createWallet("admin").addr;

    SourceCore sourceCore;
    MellowInteropBalanceChecker mellowInteropBalanceChecker;

    function setUp() public {
        sourceCore = _deploySourceCore();
        mellowInteropBalanceChecker = new MellowInteropBalanceChecker();
    }

    function testTokenBalances() public {
        address userA = vm.createWallet("userA").addr;
        address userB = vm.createWallet("userB").addr;
        address userC = vm.createWallet("userC").addr; // Won't deposit anything

        _deposit(userA, 0.5 ether);
        _deposit(userB, 1 ether);

        address[] memory addresses = new address[](3);
        addresses[0] = userA;
        addresses[1] = userB;
        addresses[2] = userC;

        uint256[] memory balances = mellowInteropBalanceChecker.tokenBalances(address(sourceCore), addresses);
        assertEq(balances[0], 0.5 ether);
        assertEq(balances[1], 1 ether);
        assertEq(balances[2], 0);
    }

    function testBatchTokenBalances() public {
        address userA = vm.createWallet("userA").addr;
        address userB = vm.createWallet("userB").addr;
        address userC = vm.createWallet("userC").addr; // Won't deposit anything

        _deposit(userA, 0.5 ether);
        _deposit(userB, 1 ether);

        address[] memory sources = new address[](1);
        sources[0] = address(sourceCore);

        address[] memory addresses = new address[](3);
        addresses[0] = userA;
        addresses[1] = userB;
        addresses[2] = userC;

        uint256[] memory balances = mellowInteropBalanceChecker.batchTokenBalances(sources, addresses);
        assertEq(balances[0], 0.5 ether);
        assertEq(balances[1], 1 ether);
        assertEq(balances[2], 0);
    }

    function testBatchTokenBalances_MultipleSources() public {
        SourceCore sourceCore2 = _deploySourceCore();

        address userA = vm.createWallet("userA").addr;
        address userB = vm.createWallet("userB").addr;
        address userC = vm.createWallet("userC").addr; // Won't deposit anything

        _deposit(userA, 0.5 ether);
        _deposit(userB, 1 ether);

        _depositTo(address(sourceCore2), userA, 0.5 ether);
        _depositTo(address(sourceCore2), userB, 1 ether);

        address[] memory sources = new address[](2);
        sources[0] = address(sourceCore);
        sources[1] = address(sourceCore2);

        address[] memory addresses = new address[](3);
        addresses[0] = userA;
        addresses[1] = userB;
        addresses[2] = userC;

        uint256[] memory balances = mellowInteropBalanceChecker.batchTokenBalances(sources, addresses);
        assertEq(balances[0], 1 ether);
        assertEq(balances[1], 2 ether);
        assertEq(balances[2], 0);
    }

    function _deposit(address user, uint256 amount) internal {
        _depositTo(address(sourceCore), user, amount);
    }

    function _depositTo(address source, address user, uint256 amount) internal {
        vm.startPrank(user);
        deal(Constants.wsteth(), user, amount);
        IERC20(Constants.wsteth()).approve(source, amount);
        SourceCore(source).deposit(amount, user);
        vm.stopPrank();
    }

    function _deploySourceCore() internal returns (SourceCore) {
        address singleton = address(new SourceCore());
        SourceCore _sourceCore = SourceCore(
            address(
                new TransparentUpgradeableProxy(
                    singleton,
                    proxyAdmin,
                    new bytes(0)
                )
            )
        );
        MellowOFTAdapter mellowOFTAdapter = new MellowOFTAdapter(Constants.wsteth(), Constants.endpointV2(), admin);
        _sourceCore.initialize(
            ISourceCoreStorage.InitParams({
                name: "SourceCoreName",
                symbol: "SourceCoreSymbol",
                admin: admin,
                mellowOFTAdapter: address(mellowOFTAdapter),
                epochDuration: 1 weeks,
                targetEndpointId: 2,
                targetCoreAddress: bytes32(uint256(1)),
                limit: type(uint256).max,
                pushRoleHolder: admin,
                setWithdrawalDelayRoleHolder: admin,
                setValueRoleHolder: admin,
                setMaxAgeRoleHolder: admin,
                setLimitRoleHolder: address(0),
                oracleMaxAge: 7 days
            })
        );
        return _sourceCore;
    }
}
