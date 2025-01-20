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

    /// @notice Calls setUp from TestHelper and initializes contract instances for testing.
    function setUp() public virtual override {
        super.setUp();

        // Setup function to initialize 2 Mock Endpoints with Mock MessageLib.
        setUpEndpoints(2, LibraryType.UltraLightNode);

        // Initializes 2 MyOApps; one on chain A, one on chain B.
        address[] memory sender = setupOApps(type(LayerZeroAdapter).creationCode, 1, 2);
        sourceAdapter = LayerZeroAdapter(payable(sender[0]));
        targetAdapter = LayerZeroAdapter(payable(sender[1]));

        claimer = new MockClaimer();

        targetCore = new TargetCore(targetCoreOwner, address(claimer), "TargetName", "TargetSymbol");
        sourceCore = new SourceCore(sourceCoreOwner, Constants.WSTETH(), "SourceName", "SourceSymbol");
        vault = new MockVault("name", "symbol", address(targetCore.asset()));

        vm.startPrank(sourceAdapter.owner());
        sourceAdapter.setCore(address(sourceCore));
        sourceAdapter.setDstEid(2);
        sourceAdapter.setGasReceiver(sourceAdapter.owner());
        vm.stopPrank();

        vm.startPrank(targetAdapter.owner());
        targetAdapter.setCore(address(targetCore));
        targetAdapter.setDstEid(1);
        targetAdapter.setGasReceiver(targetAdapter.owner());
        vm.stopPrank();

        targetCore.initialize(address(vault), vm.createWallet("burner").addr, address(targetAdapter));
        sourceCore.initialize(address(0), 100 ether, false, false, false, 0, address(sourceAdapter));
    }

    function testPushDeposits() public {
        address user = vm.createWallet("user").addr;
        vm.startPrank(user);
        address wsteth = Constants.WSTETH();
        deal(wsteth, user, 1 ether);
        deal(user, 2 ether);
        IERC20(wsteth).approve(address(sourceCore), 1 ether);
        uint256 batchId = sourceCore.deposit{value: 0.001 ether}(1 ether, user);

        bytes memory extraOptions = OptionsBuilder.newOptions().addExecutorLzReceiveOption(1e6, 0);
        uint256 targetFee = targetAdapter.quoteMessage(
            IAdapter.MessageType.DEPOSIT,
            targetAdapter.encodeMessage(
                IAdapter.MessageType.DEPOSIT, abi.encode(type(uint256).max, type(uint256).max), new bytes(0)
            ),
            extraOptions
        );

        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(1e6, uint128(targetFee));
        bytes memory fullMessage = sourceAdapter.encodeMessage(
            IAdapter.MessageType.DEPOSIT, abi.encode(type(uint256).max, type(uint256).max), extraOptions
        );

        sourceCore.pushDepositBatch{value: 1 ether}(batchId, options, extraOptions);
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

            bytes memory extraOptions = OptionsBuilder.newOptions().addExecutorLzReceiveOption(1e6, 0);
            uint256 targetFee = targetAdapter.quoteMessage(
                IAdapter.MessageType.DEPOSIT,
                targetAdapter.encodeMessage(
                    IAdapter.MessageType.DEPOSIT, abi.encode(type(uint256).max, type(uint256).max), new bytes(0)
                ),
                extraOptions
            );

            bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(1e6, uint128(targetFee));
            bytes memory fullMessage = sourceAdapter.encodeMessage(
                IAdapter.MessageType.DEPOSIT, abi.encode(type(uint256).max, type(uint256).max), extraOptions
            );

            sourceCore.pushDepositBatch{value: 1 ether}(batchId, options, extraOptions);
            vm.stopPrank();

            verifyPackets(targetEid, addressToBytes32(address(targetAdapter)));
            verifyPackets(sourceEid, addressToBytes32(address(sourceAdapter)));
        }

        vm.startPrank(user);
        sourceCore.claimDeposits(new uint256[](1), user);

        sourceCore.redeem(1 ether, user);
        {
            deal(user, 2 ether);
            bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(1e6, 0);
            sourceCore.pushRedeemBatch{value: 1 ether}(0, options, new bytes(0));

            verifyPackets(targetEid, addressToBytes32(address(targetAdapter)));

            targetCore.claim{value: 1 ether}(
                0, abi.encode(new uint256[](0), new uint256[][](0), type(uint256).max), options
            );

            verifyPackets(sourceEid, addressToBytes32(address(sourceAdapter)));

            sourceCore.claimRedeems(new uint256[](1), user);
        }
        vm.stopPrank();
    }
}
