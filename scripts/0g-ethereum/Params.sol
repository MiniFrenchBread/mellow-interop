// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../Constants.sol";

library Params {
    address constant targetCoreImpl = 0xC26C59540Fe0FFc25FE97fB09a995B4D07E0Dfb2; // Ethereum TargetCore implementation
    address constant sourceCoreImpl = 0x87C7AeD3d021C3b2798361bC33B6d427CFa465B5; // OG SourceCore implementation

    uint256 constant sourceChainId = Constants.ETHEREUM_CHAINID;
    uint256 constant targetChainId = Constants.OG_CHAINID;

    address constant targetVault = address(0);
    address constant targetCore = address(0);
    address constant sourceCore = address(0);
    address constant mellowOFTAdapter = address(0);
    address constant mellowOFT = address(0);

    address constant proxyAdmin = 0x3622B8C85C9a4A2ecda005349045FB80912D38f7;
    address constant vaultAdmin = 0x3622B8C85C9a4A2ecda005349045FB80912D38f7;
    address constant curator = 0x3622B8C85C9a4A2ecda005349045FB80912D38f7;
    address constant operator = 0x3622B8C85C9a4A2ecda005349045FB80912D38f7;
    address constant asset = 0x1Cd0690fF9a693f5EF2dD976660a8dAFc81A109c;

    string constant oftName = "OG Vault OFT";
    string constant oftSymbol = "OG OFT";
    string constant vaultName = "Staked 0G";
    string constant vaultSymbol = "st0G";

    uint256 constant limit = type(uint256).max / 2;
    uint256 constant EPOCH_DURATION = 1 days;
    uint256 constant ORACLE_MAX_AGE = 21 days;
    uint256 constant WITHDRAWAL_DELAY = 22 days;
    address constant claimer = 0x25024a3017B8da7161d8c5DCcF768F8678fB5802; // Mellow Ethereum claimer
}
