// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/InitSource.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    /*
        [bsc] SourceCore SOLV 0x7C942105Be8Be5B3cbB7309120b0C0C16ee3e536;
        [bsc] MellowOFTAdapter SOLV 0xAEa7F7bF3A3b40e625b160e21473dAC1D6089DD9.
        [ethereum] TargetCore SOLV 0x927F0604c60924399EB44f54C4c333Ed1Ef21B45;
        [ethereum] MellowOFT SOLV 0x080cCaa313B0e0Bac744C090B5894d75d853518D.
    */

    uint256 public constant EPOCH_DURATION = 1 days;
    uint256 public constant ORACLE_MAX_AGE = 21 days;
    uint256 public constant WITHDRAWAL_DELAY = 22 days;

    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);
        {
            SourceCore sourceCore = SourceCore(0x7C942105Be8Be5B3cbB7309120b0C0C16ee3e536);
            address targetCoreAddress = 0x927F0604c60924399EB44f54C4c333Ed1Ef21B45;
            uint32 targetEid = Constants.endpointId(Constants.ETHEREUM_CHAINID);
            MellowOFTAdapter mellowOFTAdapter = MellowOFTAdapter(0xAEa7F7bF3A3b40e625b160e21473dAC1D6089DD9);
            MellowOFT mellowOFT = MellowOFT(0x080cCaa313B0e0Bac744C090B5894d75d853518D);

            InitSource.init(
                InitSource.InitParams({
                    deployer: deployer,
                    vaultAdmin: Constants.SOLV_MAINNET_VAULT_ADMIN(),
                    vaultProxyAdmin: Constants.SOLV_MAINNET_VAULT_PROXY_ADMIN(),
                    oracleUpdater: Constants.SOLV_MAINNET_VAULT_ADMIN(),
                    curatorAdmin: Constants.SOLV_MAINNET_CURATOR(),
                    curatorOperator: Constants.SOLV_MAINNET_CURATOR_OPERATOR(),
                    sourceCore: sourceCore,
                    targetEid: targetEid,
                    targetCoreAddress: targetCoreAddress,
                    mellowOFTAdapter: mellowOFTAdapter,
                    mellowOFT: mellowOFT,
                    name: "SOLV Vault",
                    symbol: "SOLV",
                    epochDuration: EPOCH_DURATION,
                    limit: 550000000 ether, // 550000000 SOLV
                    oracleMaxAge: ORACLE_MAX_AGE,
                    withdrawalDelay: WITHDRAWAL_DELAY
                })
            );
        }
        vm.stopBroadcast();
        // revert("ok");
    }
}
