// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "./Imports.sol";

contract CrosschainTest is TestHelperOz5 {
    using OptionsBuilder for bytes;

    uint16 public immutable sourceEid = 1;
    uint16 public immutable targetEid = 2;

    LayerZeroAdapter public sourceAdapter;
    LayerZeroAdapter public targetAdapter;

    TargetCore public targetCore;
    SourceCore public sourceCore;

    address public targetCoreOwner = vm.createWallet("target-core-owner").addr;
    address public sourceCoreOwner = vm.createWallet("source-core-owner").addr;

    MockVault public vault;
    MockClaimer public claimer;

    function setupOApps(bytes memory _oappCreationCode, address[2] memory cores, address gasReceiver_)
        public
        returns (address sourceOApp, address targetOApp)
    {
        address[] memory oapps = new address[](2);

        oapps[0] = _deployOApp(
            _oappCreationCode, abi.encode(address(endpoints[1]), address(this), cores[0], uint32(2), gasReceiver_)
        );
        oapps[1] = _deployOApp(
            _oappCreationCode, abi.encode(address(endpoints[2]), address(this), cores[1], uint32(1), gasReceiver_)
        );
        // config
        wireOApps(oapps);

        return (oapps[0], oapps[1]);
    }

    /// @notice Calls setUp from TestHelper and initializes contract instances for testing.
    function setUp() public virtual override {
        super.setUp();
        setUpEndpoints(2, LibraryType.UltraLightNode);

        claimer = new MockClaimer();
        targetCore = new TargetCore("TargetCoreStorage", 1);
        sourceCore = new SourceCore("SourceCoreStorage", 1);

        (address sourceAdapter_, address targetAdapter_) =
            setupOApps(type(LayerZeroAdapter).creationCode, [address(sourceCore), address(targetCore)], address(this));
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
            targetCoreOwner,
            address(vault),
            vm.createWallet("burner").addr,
            address(targetAdapter),
            address(claimer),
            "TargetName",
            "TargetSymbol"
        );
        vault.init("name", "symbol", address(targetCore.asset()));
        sourceCore.initialize(
            ISourceCore.InitParams(
                sourceCoreOwner,
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

    function testPushDeposits() public {
        address user = vm.createWallet("user").addr;
        vm.startPrank(user);
        address wsteth = Constants.WSTETH();
        deal(wsteth, user, 1 ether);
        deal(user, 2 ether);
        IERC20(wsteth).approve(address(sourceCore), 1 ether);
        uint256 batchId = sourceCore.deposit{value: 0.001 ether}(1 ether, user);

        uint256 targetFee = targetAdapter.quoteMessage(
            IAdapter.MessageType.DEPOSIT,
            targetAdapter.encodeMessage(IAdapter.MessageType.DEPOSIT, abi.encode(type(uint256).max, type(uint256).max)),
            new bytes(0)
        );

        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(1e6, uint128(targetFee));
        bytes memory fullMessage =
            sourceAdapter.encodeMessage(IAdapter.MessageType.DEPOSIT, abi.encode(type(uint256).max, type(uint256).max));

        sourceCore.pushDepositBatch{value: 1 ether}(batchId);
        vm.stopPrank();

        verifyPackets(targetEid, addressToBytes32(address(targetAdapter)));
        verifyPackets(sourceEid, addressToBytes32(address(sourceAdapter)));

        vm.startPrank(user);
        sourceCore.claimDeposits(new uint256[](1), user);
        vm.stopPrank();
    }

    function testPushRedeems() public {
        address user = vm.createWallet("user").addr;
        vm.startPrank(user);
        address wsteth = Constants.WSTETH();
        {
            deal(wsteth, user, 1 ether);
            deal(user, 2 ether);
            IERC20(wsteth).approve(address(sourceCore), 1 ether);
            uint256 batchId = sourceCore.deposit{value: 0.001 ether}(1 ether, user);

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

            vm.startPrank(user);
            deal(user, 1 ether);
            targetCore.pushDeposit{value: 1 ether}(batchId);

            vm.stopPrank();
            verifyPackets(sourceEid, addressToBytes32(address(sourceAdapter)));
        }

        vm.startPrank(user);
        sourceCore.claimDeposits(new uint256[](1), user);

        sourceCore.redeem(1 ether, user);
        {
            deal(user, 2 ether);
            sourceCore.pushRedeemBatch{value: 1 ether}(0);

            verifyPackets(targetEid, addressToBytes32(address(targetAdapter)));

            targetCore.claim{value: 1 ether}(0, abi.encode(new uint256[](0), new uint256[][](0), type(uint256).max));

            verifyPackets(sourceEid, addressToBytes32(address(sourceAdapter)));

            sourceCore.claimRedeems(new uint256[](1), user);
        }
        vm.stopPrank();
    }
}
