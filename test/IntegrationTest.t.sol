// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "./Imports.sol";

contract IntegrationTest is TestHelperOz5 {
    using RandomLib for RandomLib.Storage;

    using OptionsBuilder for bytes;

    uint16 public immutable sourceEid = 1;
    uint16 public immutable targetEid = 2;

    TargetCore public targetCore;
    SourceCore public sourceCore;
    MellowOFT public mellowOFT;
    MellowOFTAdapter public mellowOFTAdapter;

    Oracle public oracle;
    WithdrawalQueue public withdrawalQueue;

    address public coreOwner = vm.createWallet("core-owner").addr;
    address public coreOperator = vm.createWallet("core-operator").addr;
    address public proxyAdmin = vm.createWallet("proxy-admin").addr;
    address public user = vm.createWallet("user").addr;

    Delegator public sourceDelegator;
    Delegator public targetDelegator;

    MockVault public vault;
    MockClaimer public claimer;
    RandomLib.Storage private rnd;

    function setUp() public virtual override {
        super.setUp();
        setUpEndpoints(2, LibraryType.UltraLightNode);
        mellowOFTAdapter = new MellowOFTAdapter(Constants.WSTETH(), endpoints[sourceEid], address(this));
        mellowOFT = new MellowOFT("MellowOFTName", "MellowOFTSymbol", endpoints[targetEid], address(this));

        sourceDelegator = new Delegator(coreOwner, coreOperator, endpoints[sourceEid]);
        targetDelegator = new Delegator(coreOwner, coreOperator, endpoints[targetEid]);

        mellowOFTAdapter.setPeer(targetEid, addressToBytes32(address(mellowOFT)));
        mellowOFT.setPeer(sourceEid, addressToBytes32(address(mellowOFTAdapter)));

        mellowOFTAdapter.transferOwnership(address(sourceDelegator));
        mellowOFT.transferOwnership(address(targetDelegator));

        SourceCore sourceCoreSingleton = new SourceCore();
        TargetCore targetCoreSingleton = new TargetCore();

        sourceCore =
            SourceCore(address(new TransparentUpgradeableProxy(address(sourceCoreSingleton), proxyAdmin, new bytes(0))));

        targetCore =
            TargetCore(address(new TransparentUpgradeableProxy(address(targetCoreSingleton), proxyAdmin, new bytes(0))));

        sourceCore.initialize(
            ISourceCoreStorage.InitParams({
                admin: coreOwner,
                name: "SourceCoreName",
                symbol: "SourceCoreSymbol",
                mellowOFTAdapter: address(mellowOFTAdapter),
                epochDuration: 1 weeks,
                targetEndpointId: targetEid,
                targetCoreAddress: addressToBytes32(address(targetCore)),
                limit: 100 ether,
                pushRoleHolder: coreOperator,
                setWithdrawalDelayRoleHolder: coreOwner,
                setValueRoleHolder: coreOperator,
                setMaxAgeRoleHolder: coreOwner,
                setLimitRoleHolder: coreOperator,
                oracleMaxAge: 7 days
            })
        );

        vault = new MockVault();
        vault.init("MockVaultName", "MockVaultSymbol", address(mellowOFT));
        claimer = new MockClaimer();

        targetCore.initialize(
            ITargetCoreStorage.InitParams({
                admin: coreOwner,
                vault: address(vault),
                claimer: address(claimer),
                sourceEndpointId: sourceEid,
                sourceCoreAddress: addressToBytes32(address(sourceCore)),
                depositRoleHolder: coreOperator,
                redeemRoleHolder: coreOperator,
                claimRoleHolder: coreOperator,
                pushRoleHolder: coreOperator
            })
        );

        oracle = Oracle(address(sourceCore.oracle()));
        withdrawalQueue = WithdrawalQueue(address(sourceCore.withdrawalQueue()));

        vm.startPrank(coreOwner);
        {
            EnforcedOptionParam[] memory enforcedOptions = new EnforcedOptionParam[](1);
            enforcedOptions[0] = EnforcedOptionParam({
                eid: targetEid,
                msgType: mellowOFT.SEND(),
                options: OptionsBuilder.newOptions().addExecutorLzReceiveOption(1e6, 0)
            });
            sourceDelegator.call(
                address(mellowOFTAdapter), abi.encodeCall(IOAppOptionsType3.setEnforcedOptions, (enforcedOptions)), 0
            );

            enforcedOptions[0] = EnforcedOptionParam({
                eid: sourceEid,
                msgType: mellowOFTAdapter.SEND(),
                options: OptionsBuilder.newOptions().addExecutorLzReceiveOption(1e6, 0)
            });
            targetDelegator.call(
                address(mellowOFT), abi.encodeCall(IOAppOptionsType3.setEnforcedOptions, (enforcedOptions)), 0
            );
        }
        oracle.setMaxAge(5 weeks);
        vm.stopPrank();

        vm.startPrank(coreOperator);
        oracle.setValue(1 ether);
        sourceCore.setLimit(200 ether);
        vm.stopPrank();
    }

    function logBalances(string memory t) public view {
        address wsteth = Constants.WSTETH();
        console2.log(t);
        console2.log("wsteth source balance:", IERC20(wsteth).balanceOf(address(sourceCore)));
        console2.log("oft target balance:", mellowOFT.balanceOf(address(targetCore)));
        console2.log("target vault balance:", vault.totalAssets());
        console2.log("user source lp balance:", sourceCore.balanceOf(user));
        console2.log("user source asset balance:", IERC20(wsteth).balanceOf(user));
        console2.log("withdrawal queue source lp balance:", sourceCore.balanceOf(address(withdrawalQueue)));
        console2.log("withdrawal queue source asset balance:", IERC20(wsteth).balanceOf(address(withdrawalQueue)));
        console2.log();
    }

    function testCompleteWorkflow() external {
        vm.startPrank(user);
        {
            address wsteth = Constants.WSTETH();
            deal(wsteth, user, 10 ether);
            IERC20(wsteth).approve(address(sourceCore), 10 ether);
            sourceCore.deposit(0.5 ether, user);
            sourceCore.mint(0.5 ether, user);
        }
        vm.stopPrank();
        logBalances("before push");

        vm.startPrank(coreOperator);
        deal(coreOperator, 1 ether);
        sourceCore.pushToTarget{value: 1 ether}();
        vm.stopPrank();
        logBalances("after push to target");

        verifyPackets(targetEid, addressToBytes32(address(mellowOFT)));
        logBalances("after verification");

        vm.startPrank(coreOperator);
        targetCore.deposit(1 ether);
        vm.stopPrank();
        logBalances("after deposit");

        vm.startPrank(coreOperator);
        targetCore.redeem(1 ether);
        vm.stopPrank();
        logBalances("after redeem");

        vault.pull(address(claimer));
        logBalances("after pull");

        vm.startPrank(coreOperator);
        vm.expectRevert("TargetCore: claim failed");
        targetCore.claim(abi.encodeCall(MockClaimer.claim, (address(mellowOFT), 0)));
        targetCore.claim(abi.encodeCall(MockClaimer.claim, (address(mellowOFT), 1 ether)));
        logBalances("after claim");

        deal(coreOperator, 1 ether);
        targetCore.pushToSource{value: 0}(0);
        vm.expectRevert("TargetCore: insufficient assets", address(targetCore));
        targetCore.pushToSource{value: 1 ether}(2 ether);
        targetCore.pushToSource{value: 1 ether}(1 ether);
        vm.stopPrank();
        logBalances("after push to source");

        verifyPackets(sourceEid, addressToBytes32(address(mellowOFTAdapter)));
        logBalances("after verification");

        vm.startPrank(user);
        sourceCore.requestWithdrawal(1 ether);
        logBalances("after withdrawal request");

        skip(1 weeks);
        withdrawalQueue.handleEpoch();
        logBalances("after 1 week & handle epoch");

        skip(1 weeks);
        withdrawalQueue.handleEpoch();
        logBalances("after 2 weeks & handle epoch");

        withdrawalQueue.claim(0, user);
        logBalances("after claim");

        vm.stopPrank();

        skip(4 weeks);
        vm.expectRevert("Oracle: stale value");
        oracle.getValue();

        vm.expectRevert("Oracle: forbidden");
        oracle.setValue(1 ether + 1 gwei);

        vm.expectRevert("MellowOFTAdapter: already initialized");
        mellowOFTAdapter.initialize(address(0));

        vm.store(address(mellowOFTAdapter), bytes32(uint256(5)), bytes32(0));
        vm.expectRevert("MellowOFTAdapter: zero address");
        mellowOFTAdapter.initialize(address(0));
    }
}
