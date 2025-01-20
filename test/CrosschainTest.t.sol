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

        vm.startPrank(targetCore.owner());
        targetCore.setAdapter(address(targetAdapter));
        targetCore.setBurner(vm.createWallet("burner").addr);
        targetCore.setVault(address(vault));
        vm.stopPrank();

        vm.startPrank(sourceCore.owner());
        sourceCore.setLimit(100 ether);
        sourceCore.setAdapter(address(sourceAdapter));
        // sourceCore.setValues(0.001 ether, 0.001 ether, 0.001 ether, 0.001 ether);
        vm.stopPrank();
    }

    /// @notice Tests the send and multi-compose functionality of MyOApp.
    /// @dev Simulates message passing from A -> B and checks for data integrity.
    function testSend() public {
        // Setup variable for data values before calling send().
        // string memory dataBefore = aMyOApp.data();
        // Generates 1 lzReceive execution option via the OptionsBuilder library.
        // STEP 0: Estimating message gas fees via the quote function.
        // bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(150000, 0);
        // MessagingFee memory fee = aMyOApp.quote(bEid, "test message", options, false);

        // STEP 1: Sending a message via the _lzSend() method.
        // MessagingReceipt memory receipt = aMyOApp.send{value: fee.nativeFee}(bEid, "test message", options);

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

        uint256 sourceFee = sourceAdapter.quoteMessage(IAdapter.MessageType.DEPOSIT, fullMessage, options);
        sourceCore.pushDepositBatch{value: 1 ether}(batchId, options, extraOptions);
        vm.stopPrank();

        verifyPackets(targetEid, addressToBytes32(address(targetAdapter)));
        verifyPackets(sourceEid, addressToBytes32(address(sourceAdapter)));

        vm.startPrank(user);
        sourceCore.claimDeposits(new uint256[](1), user);
        vm.stopPrank();
    }
}
