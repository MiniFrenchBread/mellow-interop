// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "./Imports.sol";

contract IntegrationTest is TestHelperOz5 {
    using RandomLib for RandomLib.Storage;

    using OptionsBuilder for bytes;

    uint16 public immutable sourceEid = 1;
    uint16 public immutable targetEid = 2;

    LayerZeroAdapter public sourceAdapter;
    LayerZeroAdapter public targetAdapter;

    TargetCore public targetCore;
    SourceCore public sourceCore;

    address public coreOwner = vm.createWallet("core-owner").addr;
    address public coreOperator = vm.createWallet("core-operator").addr;

    MockVault public vault;
    RandomLib.Storage private rnd;

    function setupOApps(
        bytes memory _oappCreationCode,
        address[2] memory cores,
        address[2] memory delegators,
        address gasReceiver
    ) public returns (address sourceOApp, address targetOApp) {
        address[] memory oapps = new address[](2);

        oapps[0] = _deployOApp(
            _oappCreationCode, abi.encode(address(endpoints[1]), address(this), cores[0], uint32(2), gasReceiver)
        );
        oapps[1] = _deployOApp(
            _oappCreationCode, abi.encode(address(endpoints[2]), address(this), cores[1], uint32(1), gasReceiver)
        );
        wireOApps(oapps);

        Ownable(oapps[0]).transferOwnership(delegators[0]);
        Ownable(oapps[1]).transferOwnership(delegators[1]);

        return (oapps[0], oapps[1]);
    }

    function setUp() public virtual override {
        super.setUp();
        setUpEndpoints(2, LibraryType.UltraLightNode);

        address claimer = address(1324);
        targetCore = TargetCore(
            address(
                new TransparentUpgradeableProxy(
                    address(new TargetCore("TargetCoreStorage", 1)), address(0xdead), new bytes(0)
                )
            )
        );
        sourceCore = SourceCore(
            address(
                new TransparentUpgradeableProxy(
                    address(new SourceCore("SourceCoreStorage", 1)), address(0xdead), new bytes(0)
                )
            )
        );
        Delegator sourceDelegator = new Delegator(coreOwner, coreOperator, endpoints[1]);
        Delegator targetDelegator = new Delegator(coreOwner, coreOperator, endpoints[2]);
        (address sourceAdapter_, address targetAdapter_) = setupOApps(
            type(LayerZeroAdapter).creationCode,
            [address(sourceCore), address(targetCore)],
            [address(sourceDelegator), address(targetDelegator)],
            coreOperator
        );
        sourceAdapter = LayerZeroAdapter(payable(sourceAdapter_));
        targetAdapter = LayerZeroAdapter(payable(targetAdapter_));

        vm.startPrank(sourceAdapter.owner());
        sourceAdapter.setGasReceiver(sourceAdapter.owner());
        vm.stopPrank();

        vm.startPrank(targetAdapter.owner());
        targetAdapter.setGasReceiver(targetAdapter.owner());
        vm.stopPrank();

        vault = new MockVault();
        targetCore.initialize(
            coreOwner, address(vault), address(targetAdapter), address(claimer), "TargetName", "TargetSymbol"
        );
        vault.init("name", "symbol", address(targetCore.asset()));
        sourceCore.initialize(
            ISourceCore.InitParams(
                coreOwner,
                address(0),
                100 ether,
                false,
                false,
                false,
                address(sourceAdapter),
                Constants.WSTETH(),
                "SourceName",
                "SourceSymbol"
            )
        );
        {
            vm.startPrank(targetAdapter.owner());
            EnforcedOptionParam[] memory params = new EnforcedOptionParam[](uint256(type(IAdapter.MessageType).max) + 1);
            for (uint256 i = 0; i < params.length; i++) {
                params[i] = EnforcedOptionParam({
                    eid: targetAdapter.dstEid(),
                    msgType: uint16(i),
                    options: OptionsBuilder.newOptions().addExecutorLzReceiveOption(1e6, 0)
                });
            }
            targetAdapter.setEnforcedOptions(params);
            vm.stopPrank();
        }

        {
            vm.startPrank(sourceAdapter.owner());
            EnforcedOptionParam[] memory params = new EnforcedOptionParam[](uint256(type(IAdapter.MessageType).max) + 1);
            for (uint256 i = 0; i < params.length; i++) {
                params[i] = EnforcedOptionParam({
                    eid: sourceAdapter.dstEid(),
                    msgType: uint16(i),
                    options: OptionsBuilder.newOptions().addExecutorLzReceiveOption(1e6, 0)
                });
            }
            sourceAdapter.setEnforcedOptions(params);
            vm.stopPrank();
        }
    }

    // WIP
    function requestDepositTransition() internal {}
    function pushDepositBatchSourceTransition() internal {}
    function cancelDepositTransition() internal {}
    function claimDepositTransition() internal {}

    function requestRedeemTransition() internal {}
    function pushRedeemTransition() internal {}
    function cancelRedeemTransition() internal {}
    function claimRedeemTransition() internal {}

    function verifyPacketSourceTransition() internal {}
    function verifyPacketTargetTransition() internal {}

    function rejectRedeemBatchTransition() internal {}
    function rejectDepositBatchTransition() internal {}
    function claimTransition() internal {}
    function retryClaimTransition() internal {}
    function pushDepositBatchTargetTransition() internal {}
    function retryPushDepositBatchTransition() internal {}

    function()[1] internal transitions = [requestDepositTransition];

    function validate() internal {}

    function testSimulation() external {
        rnd.seed = 42;
        uint256 iterations = rnd.randInt(10, 100);

        for (uint256 i = 0; i < iterations; i++) {
            function() internal transition = transitions[rnd.randInt(0, transitions.length - 1)];
            transition();
            validate();
        }

        address user = vm.createWallet("user").addr;
        vm.startPrank(user);
        address wsteth = Constants.WSTETH();
        {
            deal(wsteth, user, 1 ether);
            deal(user, 2 ether);
            IERC20(wsteth).approve(address(sourceCore), 1 ether);
            uint256 batchId = sourceCore.requestDeposit{value: 0.001 ether}(1 ether);

            uint256 targetFee = targetAdapter.quoteMessage(
                IAdapter.MessageType.DEPOSIT,
                targetAdapter.encodeMessage(
                    IAdapter.MessageType.DEPOSIT, abi.encode(type(uint256).max, type(uint256).max)
                ),
                new bytes(0)
            );

            bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(1e6, uint128(targetFee));
            bytes memory fullMessage = sourceAdapter.encodeMessage(
                IAdapter.MessageType.DEPOSIT, abi.encode(type(uint256).max, type(uint256).max)
            );

            sourceCore.pushDepositBatch{value: 1 ether}(batchId);
            vm.stopPrank();

            verifyPackets(targetEid, addressToBytes32(address(targetAdapter)));

            vm.startPrank(targetCore.getRoleMember(0x00, 0));
            targetCore.grantRole(targetCore.OPERATOR_ROLE(), user);
            vm.stopPrank();

            vm.startPrank(coreOwner);
            deal(coreOwner, 1 ether);
            targetCore.pushDepositBatch{value: 1 ether}(batchId);
            vm.stopPrank();

            verifyPackets(sourceEid, addressToBytes32(address(sourceAdapter)));
        }

        vm.startPrank(user);
        sourceCore.claimDeposits(new uint256[](1), user);

        sourceCore.requestRedeem(1 ether);
        {
            deal(user, 2 ether);
            sourceCore.pushRedeemBatch{value: 1 ether}(0);

            verifyPackets(targetEid, addressToBytes32(address(targetAdapter)));

            targetCore.claim{value: 1 ether}(0, new bytes(0));

            verifyPackets(sourceEid, addressToBytes32(address(sourceAdapter)));

            sourceCore.claimRedeems(new uint256[](1), user);
        }
        vm.stopPrank();
    }
}
