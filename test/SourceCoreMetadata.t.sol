// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {SourceCore} from "../src/core/SourceCore.sol";

/// @dev The live proxy was initialized with the network spelled "OG" -- a capital letter O where
///      it is a digit zero. The initializer cannot run again, so the getters are overridden
///      instead. These pin the corrected spelling, and pin that it costs no storage: an
///      uninitialized instance answers, which it could not do if the strings were still read
///      from a slot.
contract SourceCoreMetadataTest is Test {
    SourceCore internal core;

    function setUp() external {
        core = new SourceCore();
    }

    function testNameUsesDigitZero() external view {
        assertEq(core.name(), "Ascend Staked 0G");
    }

    function testSymbolUsesDigitZero() external view {
        assertEq(core.symbol(), "a0G");
    }

    function testMetadataNeedsNoInitialization() external view {
        // `new SourceCore()` runs `_disableInitializers()`, so this instance has no stored
        // metadata at all. Both getters still answer, proving they read no storage.
        assertGt(bytes(core.name()).length, 0);
        assertGt(bytes(core.symbol()).length, 0);
    }

    function testOnlyTheTwoStringGettersStoppedReadingStorage() external view {
        // decimals() still comes from the base contract, where it reads `_underlyingDecimals`
        // as written by `__ERC4626_init`. This instance was never initialized, so it answers 0.
        // That contrast is the point: name() and symbol() answer on the same instance because
        // they no longer read a slot, while everything else was left alone.
        assertEq(core.decimals(), 0);
    }
}
