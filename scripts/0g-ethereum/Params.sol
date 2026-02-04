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

    address constant helperBot = 0xc0412361882961570d79CE535cB26Fc71bf363A7; // OG helper bot EOA
    /*
    Roles on source (0G):
           vaultAdmin: DEFAULT_ADMIN_ROLE, SET_MAX_AGE_ROLE
              curator: SET_LIMIT_ROLE
             operator: PUSH_ROLE
        oracleUpdater: SET_VALUE_ROLE

    Roles on target (Ethereum):
           vaultAdmin: DEFAULT_ADMIN_ROLE, OFT delegate
             operator: DEPOSIT_ROLE, REDEEM_ROLE, CLAIM_ROLE, PUSH_ROLE
    */
    address constant proxyAdmin = 0xEF1c19bDEE7fE61a1B2b98375D2003f57e4B2B8a; // 5/8 Mellow+0g 4+4 Ethereum+0G
    address constant vaultAdmin = 0xfc7350b0d7a358Db58875148faF3bDEAaFC82911; // 5/8 Mellow+0g 4+4 Ethereum+0G
    address constant curator = 0xc6eA3826A7a357162d01e22044D845522f62BB4c; // 0G 3/4 
    address constant operator = helperBot;
    address constant asset = 0x1Cd0690fF9a693f5EF2dD976660a8dAFc81A109c; // W0G

    string constant oftName = "0G Vault OFT";
    string constant oftSymbol = "0G OFT";
    string constant vaultName = "Staked 0G";
    string constant vaultSymbol = "st0G";

    uint256 constant limit = type(uint256).max / 2;
    uint256 constant EPOCH_DURATION = 1 days;
    uint256 constant ORACLE_MAX_AGE = 21 days;
    uint256 constant WITHDRAWAL_DELAY = 22 days;
    address constant claimer = 0x25024a3017B8da7161d8c5DCcF768F8678fB5802; // Mellow Ethereum claimer
}
