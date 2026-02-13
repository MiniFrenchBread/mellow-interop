// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../Constants.sol";
/*    
  SourceCore impl 0x87C7AeD3d021C3b2798361bC33B6d427CFa465B5
  TargetCore impl 0x1bfbF13aF629eB2bC829393D10f5f4a2B84EFF70
  
  OG Vault: 0x0Ff6ea4CAD58b9e54535Ae1eA2452cdbfFb9bfaB
  SourceCore Ascend Staked OG/aOG 0x4B3c2f55fa67679b382c979A082Df1B32079B4cB
  MellowOFTAdapter 0x28eCbDbf7AA257A42D786409c7a27B9CE92aA1fF
  TargetCore OG 0xd46E464c82643e6937838A94d40FD8D014A2EA26
  MellowOFT OG 0G Vault OFT/0G OFT 0xE42215BD71E190b3864267569c2f66077260EaE4
  WithdrawalQueue 0x10A98a5344742308744Bd59829786584A12C1146
  Oracle 0x8f7b85432F7BB3534ca34E42c215146Db47a4Eab
*/
library Params {
    address constant targetCoreImpl = 0x1bfbF13aF629eB2bC829393D10f5f4a2B84EFF70; // Ethereum TargetCore implementation
    address constant sourceCoreImpl = 0x87C7AeD3d021C3b2798361bC33B6d427CFa465B5; // OG SourceCore implementation

    uint256 constant sourceChainId = Constants.OG_CHAINID;
    uint256 constant targetChainId = Constants.ETHEREUM_CHAINID;

    address constant targetVault = address(0x0Ff6ea4CAD58b9e54535Ae1eA2452cdbfFb9bfaB);
    address constant targetCore = address(0xd46E464c82643e6937838A94d40FD8D014A2EA26);
    address constant sourceCore = address(0x4B3c2f55fa67679b382c979A082Df1B32079B4cB);
    address constant mellowOFTAdapter = address(0x28eCbDbf7AA257A42D786409c7a27B9CE92aA1fF);
    address constant mellowOFT = address(0xE42215BD71E190b3864267569c2f66077260EaE4);

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
    string constant vaultName = "Ascend Staked OG";
    string constant vaultSymbol = "aOG";

    uint256 constant limit = type(uint256).max / 2;
    uint256 constant EPOCH_DURATION = 1 days;
    uint256 constant ORACLE_MAX_AGE = 21 days;
    uint256 constant WITHDRAWAL_DELAY = 22 days;
    address constant claimer = 0x25024a3017B8da7161d8c5DCcF768F8678fB5802; // Mellow Ethereum claimer
}
