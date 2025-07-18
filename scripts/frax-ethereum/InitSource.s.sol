// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../common/InitSource.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    /*
        SourceCore FRAX 0x24dD1eaBEad7b3cB07b7d162439ec0A4EEC703DF;
        MellowOFTAdapter FRAX 0x24E6D68a553BA3146E10CDb06e9dB996Cea2bbBa.
        TargetCore FRAX 0x6408a5261578E17f858ADD039dEb72E1952E9Fe9;
        MellowOFT FRAX 0xf85932AcE734E3CF04b5c2a6Cb7B10f44014eCb9.
        MultiVault FRAX: 0x5B2099e204f22A0ccE3806fc2093713E2780D437.
    */

    uint256 public constant EPOCH_DURATION = 1 days;
    uint256 public constant ORACLE_MAX_AGE = 14 days;
    uint256 public constant WITHDRAWAL_DELAY = 15 days;

    function run() external {
        uint256 deployerPk = uint256(bytes32(vm.envBytes("HOT_DEPLOYER")));
        address deployer = vm.addr(deployerPk);

        vm.startBroadcast(deployerPk);
        {
            SourceCore sourceCore = SourceCore(0x24dD1eaBEad7b3cB07b7d162439ec0A4EEC703DF);
            address targetCoreAddress = 0x6408a5261578E17f858ADD039dEb72E1952E9Fe9;
            uint32 targetEid = Constants.endpointId(Constants.ETHEREUM_CHAINID);
            MellowOFTAdapter mellowOFTAdapter = MellowOFTAdapter(0x24E6D68a553BA3146E10CDb06e9dB996Cea2bbBa);
            MellowOFT mellowOFT = MellowOFT(0xf85932AcE734E3CF04b5c2a6Cb7B10f44014eCb9);

            InitSource.init(
                InitSource.InitParams({
                    deployer: deployer,
                    vaultAdmin: Constants.FRAX_ADMIN(),
                    vaultProxyAdmin: Constants.FRAX_PROXY_ADMIN(),
                    oracleUpdater: Constants.FRAX_ORACLE_UPDATER(),
                    curatorAdmin: Constants.FRAX_CURATOR_ADMIN(),
                    curatorOperator: Constants.FRAX_CURATOR_OPERATOR(),
                    sourceCore: sourceCore,
                    targetEid: targetEid,
                    targetCoreAddress: targetCoreAddress,
                    mellowOFTAdapter: mellowOFTAdapter,
                    mellowOFT: mellowOFT,
                    name: "FRAX Vault",
                    symbol: "rstFRAX",
                    epochDuration: EPOCH_DURATION,
                    limit: 1000000 ether,
                    oracleMaxAge: ORACLE_MAX_AGE,
                    withdrawalDelay: WITHDRAWAL_DELAY
                })
            );
        }
        vm.stopBroadcast();
        // revert("OK");
    }
}
