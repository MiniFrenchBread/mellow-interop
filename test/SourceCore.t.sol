// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "./Imports.sol";

contract UnitTest is Test {
    address public proxyAdmin = vm.createWallet("proxy-admin").addr;
    address public admin = vm.createWallet("admin").addr;
    address public delegator = vm.createWallet("delegator").addr;
    address public operator = vm.createWallet("operator").addr;
    address public user = vm.createWallet("user").addr;

    function testConstructor() external {
        address singleton = address(new SourceCore());

        SourceCore sourceCore =
            SourceCore(address(new TransparentUpgradeableProxy(singleton, proxyAdmin, new bytes(0))));

        assertNotEq(address(0), address(sourceCore));
    }

    function testIntegration() external {
        address singleton = address(new SourceCore());

        SourceCore sourceCore =
            SourceCore(address(new TransparentUpgradeableProxy(singleton, proxyAdmin, new bytes(0))));
        MellowOFTAdapter mellowOFTAdapter = new MellowOFTAdapter(Constants.WSTETH(), Constants.LZ_ENDPOINT(), delegator);

        vm.expectRevert("SourceCoreStorage: zero address");
        sourceCore.initialize(
            SourceCoreStorage.InitParams({
                name: "SourceCoreName",
                symbol: "SourceCoreSymbol",
                admin: address(0),
                mellowOFTAdapter: address(mellowOFTAdapter),
                epochDuration: 1 weeks,
                targetEndpointId: 2,
                targetCoreAddress: bytes32(uint256(1)),
                pushRoleHolder: operator,
                setWithdrawalDelayRoleHoler: admin,
                setValueRoleHoler: operator,
                setMaxAgeRoleHoler: admin
            })
        );

        vm.expectRevert("SourceCoreStorage: zero address");
        sourceCore.initialize(
            SourceCoreStorage.InitParams({
                name: "SourceCoreName",
                symbol: "SourceCoreSymbol",
                admin: admin,
                mellowOFTAdapter: address(0),
                epochDuration: 1 weeks,
                targetEndpointId: 2,
                targetCoreAddress: bytes32(uint256(1)),
                pushRoleHolder: operator,
                setWithdrawalDelayRoleHoler: admin,
                setValueRoleHoler: operator,
                setMaxAgeRoleHoler: admin
            })
        );

        vm.expectRevert("SourceCoreStorage: zero value");
        sourceCore.initialize(
            SourceCoreStorage.InitParams({
                name: "SourceCoreName",
                symbol: "SourceCoreSymbol",
                admin: admin,
                mellowOFTAdapter: address(mellowOFTAdapter),
                epochDuration: 0,
                targetEndpointId: 2,
                targetCoreAddress: bytes32(uint256(1)),
                pushRoleHolder: operator,
                setWithdrawalDelayRoleHoler: admin,
                setValueRoleHoler: operator,
                setMaxAgeRoleHoler: admin
            })
        );

        vm.expectRevert("SourceCoreStorage: zero value");
        sourceCore.initialize(
            SourceCoreStorage.InitParams({
                name: "SourceCoreName",
                symbol: "SourceCoreSymbol",
                admin: admin,
                mellowOFTAdapter: address(mellowOFTAdapter),
                epochDuration: 1,
                targetEndpointId: 0,
                targetCoreAddress: bytes32(uint256(1)),
                pushRoleHolder: operator,
                setWithdrawalDelayRoleHoler: admin,
                setValueRoleHoler: operator,
                setMaxAgeRoleHoler: admin
            })
        );

        vm.expectRevert("SourceCoreStorage: zero value");
        sourceCore.initialize(
            SourceCoreStorage.InitParams({
                name: "SourceCoreName",
                symbol: "SourceCoreSymbol",
                admin: admin,
                mellowOFTAdapter: address(mellowOFTAdapter),
                epochDuration: 1,
                targetEndpointId: 2,
                targetCoreAddress: bytes32(uint256(0)),
                pushRoleHolder: operator,
                setWithdrawalDelayRoleHoler: admin,
                setValueRoleHoler: operator,
                setMaxAgeRoleHoler: admin
            })
        );

        sourceCore.initialize(
            SourceCoreStorage.InitParams({
                name: "SourceCoreName",
                symbol: "SourceCoreSymbol",
                admin: admin,
                mellowOFTAdapter: address(mellowOFTAdapter),
                epochDuration: 1 weeks,
                targetEndpointId: 2,
                targetCoreAddress: bytes32(uint256(1)),
                pushRoleHolder: operator,
                setWithdrawalDelayRoleHoler: admin,
                setValueRoleHoler: operator,
                setMaxAgeRoleHoler: admin
            })
        );

        vm.expectRevert(abi.encodeWithSignature("InvalidInitialization()"));
        sourceCore.initialize(
            SourceCoreStorage.InitParams({
                name: "SourceCoreName",
                symbol: "SourceCoreSymbol",
                admin: admin,
                mellowOFTAdapter: address(mellowOFTAdapter),
                epochDuration: 1 weeks,
                targetEndpointId: 2,
                targetCoreAddress: bytes32(uint256(1)),
                pushRoleHolder: operator,
                setWithdrawalDelayRoleHoler: admin,
                setValueRoleHoler: operator,
                setMaxAgeRoleHoler: admin
            })
        );

        vm.startPrank(operator);
        sourceCore.oracle().setValue(1 ether);
        vm.stopPrank();

        vm.startPrank(admin);
        sourceCore.oracle().setMaxAge(30 days);
        sourceCore.withdrawalQueue().setWithdrawalDelay(1 weeks);
        vm.stopPrank();

        vm.startPrank(user);
        deal(Constants.WSTETH(), user, 1 ether);
        IERC20(Constants.WSTETH()).approve(address(sourceCore), 1 ether);
        sourceCore.deposit(0.5 ether, user);
        sourceCore.mint(0.5 ether, user);

        assertEq(sourceCore.balanceOf(user), 1 ether);
        assertEq(sourceCore.totalAssets(), 1 ether);

        vm.expectRevert("SourceCore: zero shares");
        sourceCore.requestWithdrawal(0);

        vm.expectRevert("SourceCore: not implemented");
        sourceCore.withdraw(1 ether, user, user);

        vm.expectRevert("SourceCore: only withdrawalQueue can pull");
        sourceCore.pull(1 ether, 1 ether);

        sourceCore.requestWithdrawal(0.5 ether);
        vm.stopPrank();

        vm.startPrank(operator);
        vm.expectRevert(abi.encodeWithSignature("NoPeer(uint32)", uint32(2)));
        sourceCore.pushToTarget();
        vm.stopPrank();

        vm.startPrank(user);

        sourceCore.requestWithdrawal(0.5 ether);
        vm.stopPrank();

        vm.startPrank(operator);
        sourceCore.pushToTarget();
        vm.stopPrank();

        vm.startPrank(user);

        skip(1 weeks);
        sourceCore.withdrawalQueue().handleEpoch();

        skip(1 weeks);
        sourceCore.withdrawalQueue().handleEpoch();

        sourceCore.withdrawalQueue().claim(0, user);

        assertNotEq(address(0), address(sourceCore.oftAdapter()));
        assertNotEq(address(0), address(sourceCore.oracle()));
        assertNotEq(0, sourceCore.targetEndpointId());
        assertNotEq(bytes32(0), sourceCore.targetCoreAddress());

        vm.stopPrank();

        vm.startPrank(address(sourceCore.withdrawalQueue()));
        vm.expectRevert(
            abi.encodeWithSignature(
                "ERC20InsufficientBalance(address,uint256,uint256)",
                address(sourceCore.withdrawalQueue()),
                uint256(0),
                uint256(1 ether)
            )
        );
        sourceCore.pull(1 ether, 1 ether);
        vm.stopPrank();

        vm.startPrank(address(0));
        vm.expectRevert("SourceCore: only withdrawalQueue can pull");
        sourceCore.pull(0, 0);
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert(
            abi.encodeWithSignature("AccessControlUnauthorizedAccount(address,bytes32)", user, sourceCore.PUSH_ROLE())
        );
        sourceCore.pushToTarget();
        vm.stopPrank();

        vm.startPrank(operator);
        sourceCore.pushToTarget();
        vm.stopPrank();
    }
}
