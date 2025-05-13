// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../Imports.sol";
import {MultiVault} from "lib/simple-lrt/src/vaults/MultiVault.sol";

abstract contract AcceptanceRunner is TestBase, StdAssertions {
    struct Deployment {
        address asset;
        uint256 limit;
        // source chain:
        uint256 sourceChainId;
        address oftAdapter;
        address sourceCore;
        address oracle;
        address withdrawalQueue;
        // target chain:
        uint256 targetChainId;
        address targetCore;
        address oft;
        address vault;
        address claimer;
        // roles:
        address vaultAdmin;
        address vaultProxyAdmin;
        address curatorAdmin;
        address curatorOperator;
        address oracleUpdater;
    }

    function addressToBytes32(address x) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(x)));
    }

    function _createArray(address x) internal pure returns (address[] memory) {
        address[] memory arr = new address[](1);
        arr[0] = x;
        return arr;
    }

    function _createArray(address x, address y) internal pure returns (address[] memory) {
        address[] memory arr = new address[](2);
        arr[0] = x;
        arr[1] = y;
        return arr;
    }

    struct Role {
        address addr;
        bytes32 role;
        address[] expectedHolders;
    }

    function runSourceAcceptance(Deployment memory $) public view {
        if (block.chainid != $.sourceChainId) {
            console2.log("Source chain ID mismatch. Expected: %s, Actual: %s", $.sourceChainId, block.chainid);
            return;
        }

        {
            Role[] memory roles = new Role[](6);
            roles[0] = Role({addr: $.sourceCore, role: 0x00, expectedHolders: _createArray($.vaultAdmin)});
            roles[1] = Role({
                addr: $.sourceCore,
                role: keccak256("SOURCE_CORE:PUSH_ROLE"),
                expectedHolders: _createArray($.curatorOperator)
            });
            roles[2] = Role({
                addr: $.sourceCore,
                role: keccak256("SOURCE_CORE:SET_LIMIT_ROLE"),
                expectedHolders: _createArray($.curatorAdmin)
            });
            roles[3] = Role({
                addr: $.sourceCore,
                role: keccak256("ORACLE:SET_VALUE_ROLE"),
                expectedHolders: _createArray($.oracleUpdater)
            });

            roles[4] = Role({
                addr: $.sourceCore,
                role: keccak256("ORACLE:SET_MAX_AGE_ROLE"),
                expectedHolders: _createArray($.vaultAdmin)
            });
            roles[5] = Role({
                addr: $.sourceCore,
                role: keccak256("WITHDRAWAL_QUEUE:SET_WITHDRAWAL_DELAY_ROLE"),
                expectedHolders: _createArray($.vaultAdmin)
            });

            runRolesAcceptance(roles);
        }

        assertEq(OFTAdapter($.oftAdapter).owner(), $.vaultAdmin);
        assertEq(OFTAdapter($.oftAdapter).token(), $.asset);

        assertEq(SourceCore($.sourceCore).targetEndpointId(), Constants.endpointId($.targetChainId));
        assertEq(
            SourceCore($.sourceCore).targetCoreAddress(), addressToBytes32($.targetCore), "Target Core address mismatch"
        );
        assertEq(address(SourceCore($.sourceCore).oracle()), $.oracle, "Oracle address mismatch");
        assertEq(
            address(SourceCore($.sourceCore).withdrawalQueue()), $.withdrawalQueue, "Withdrawal queue address mismatch"
        );
        assertEq(address(SourceCore($.sourceCore).oftAdapter()), $.oftAdapter, "OFT adapter address mismatch");
        assertEq(SourceCore($.sourceCore).limit(), $.limit, "Limit mismatch");
        // no revert!
        assertEq(SourceCore($.sourceCore).totalAssets(), 0, "Total assets mismatch");
        assertEq(SourceCore($.sourceCore).totalSupply(), 0, "Total supply mismatch");

        assertEq(Oracle($.oracle).maxAge(), 14 days, "Oracle max age mismatch");
        assertEq(Oracle($.oracle).value(), 1 ether, "Oracle value mismatch");
        assertGe(Oracle($.oracle).lastUpdated(), block.timestamp - 2 days, "Oracle last updated mismatch");

        assertEq(address(WithdrawalQueue($.withdrawalQueue).sourceCore()), $.sourceCore, "Source core address mismatch");
        assertEq(address(WithdrawalQueue($.withdrawalQueue).asset()), $.asset, "Source core address mismatch");
        assertEq(WithdrawalQueue($.withdrawalQueue).epochDuration(), 1 days, "Epoch duration mismatch");
        assertGe(
            WithdrawalQueue($.withdrawalQueue).initTimestamp(), block.timestamp - 2 days, "Init timestamp mismatch"
        );
        assertGe(WithdrawalQueue($.withdrawalQueue).withdrawalDelay(), 2 weeks, "Withdrawal delay mismatch");
        assertEq(WithdrawalQueue($.withdrawalQueue).totalShares(), 0, "Total shares mismatch");

        console2.log("Source Core: %s", $.sourceCore);
    }

    function runRolesAcceptance(Role[] memory roles) public view {
        for (uint256 i = 0; i < roles.length; i++) {
            Role memory role = roles[i];
            IAccessControlEnumerable addr_ = IAccessControlEnumerable(role.addr);
            assertEq(addr_.getRoleMemberCount(role.role), role.expectedHolders.length, "Role member count mismatch");
            for (uint256 j = 0; j < role.expectedHolders.length; j++) {
                assertEq(addr_.getRoleMember(role.role, j), role.expectedHolders[j], "Role member mismatch");
            }
        }
    }

    function runTargetAcceptance(Deployment memory $) public view {
        if (block.chainid != $.targetChainId) {
            console2.log("Target chain ID mismatch. Expected: %s, Actual: %s", $.targetChainId, block.chainid);
            return;
        }
        {
            Role[] memory roles = new Role[](21);
            roles[0] = Role({addr: $.targetCore, role: 0x00, expectedHolders: _createArray($.vaultAdmin)});
            roles[1] = Role({
                addr: $.targetCore,
                role: keccak256("TARGET_CORE:DEPOSIT_ROLE"),
                expectedHolders: _createArray($.curatorOperator)
            });
            roles[2] = Role({
                addr: $.targetCore,
                role: keccak256("TARGET_CORE:REDEEM_ROLE"),
                expectedHolders: _createArray($.curatorOperator)
            });
            roles[3] = Role({
                addr: $.targetCore,
                role: keccak256("TARGET_CORE:CLAIM_ROLE"),
                expectedHolders: _createArray($.curatorOperator)
            });
            roles[4] = Role({
                addr: $.targetCore,
                role: keccak256("TARGET_CORE:PUSH_ROLE"),
                expectedHolders: _createArray($.curatorOperator)
            });

            roles[5] = Role({addr: $.vault, role: 0x00, expectedHolders: _createArray($.vaultAdmin)});
            roles[6] = Role({
                addr: $.vault,
                role: keccak256("ADD_SUBVAULT_ROLE"),
                expectedHolders: _createArray($.curatorAdmin)
            });
            roles[7] = Role({addr: $.vault, role: keccak256("REMOVE_SUBVAULT_ROLE"), expectedHolders: new address[](0)});
            roles[8] = Role({addr: $.vault, role: keccak256("SET_STRATEGY_ROLE"), expectedHolders: new address[](0)});
            roles[9] =
                Role({addr: $.vault, role: keccak256("SET_FARM_ROLE"), expectedHolders: _createArray($.vaultAdmin)});
            roles[10] =
                Role({addr: $.vault, role: keccak256("REBALANCE_ROLE"), expectedHolders: _createArray($.curatorAdmin)});
            roles[11] =
                Role({addr: $.vault, role: keccak256("SET_DEFAULT_COLLATERAL_ROLE"), expectedHolders: new address[](0)});
            roles[12] = Role({addr: $.vault, role: keccak256("SET_ADAPTER_ROLE"), expectedHolders: new address[](0)});
            roles[13] =
                Role({addr: $.vault, role: keccak256("SET_LIMIT_ROLE"), expectedHolders: _createArray($.curatorAdmin)});
            roles[14] =
                Role({addr: $.vault, role: keccak256("PAUSE_WITHDRAWALS_ROLE"), expectedHolders: new address[](0)});
            roles[15] =
                Role({addr: $.vault, role: keccak256("UNPAUSE_WITHDRAWALS_ROLE"), expectedHolders: new address[](0)});
            roles[16] = Role({addr: $.vault, role: keccak256("PAUSE_DEPOSITS_ROLE"), expectedHolders: new address[](0)});
            roles[17] =
                Role({addr: $.vault, role: keccak256("UNPAUSE_DEPOSITS_ROLE"), expectedHolders: new address[](0)});
            roles[18] =
                Role({addr: $.vault, role: keccak256("SET_DEPOSIT_WHITELIST_ROLE"), expectedHolders: new address[](0)});
            roles[19] = Role({
                addr: $.vault,
                role: keccak256("SET_DEPOSITOR_WHITELIST_STATUS_ROLE"),
                expectedHolders: new address[](0)
            });
            roles[20] = Role({
                addr: $.vault,
                role: keccak256("RATIOS_STRATEGY_SET_RATIOS_ROLE"),
                expectedHolders: _createArray($.curatorAdmin)
            });

            runRolesAcceptance(roles);
        }

        assertEq(OFT($.oft).owner(), $.vaultAdmin, "OFT owner mismatch");

        assertEq(
            TargetCore($.targetCore).sourceEndpointId(),
            Constants.endpointId($.sourceChainId),
            "Source Endpoint ID mismatch"
        );
        assertEq(
            TargetCore($.targetCore).sourceCoreAddress(), addressToBytes32($.sourceCore), "Source Core address mismatch"
        );
        assertEq(TargetCore($.targetCore).claimer(), $.claimer, "Claimer address mismatch");
        assertEq(address(TargetCore($.targetCore).vault()), $.vault, "Vault address mismatch");
        assertEq(address(TargetCore($.targetCore).oft()), $.oft, "OFT address mismatch");
        assertEq(IERC4626($.vault).totalAssets(), 0, "Total assets mismatch");
        assertEq(IERC4626($.vault).totalSupply(), 0, "Total supply mismatch");
        assertEq(MultiVault($.vault).depositWhitelist(), true, "Deposit whitelist mismatch");
        assertEq(MultiVault($.vault).isDepositorWhitelisted($.targetCore), true, "Depositor whitelist status mismatch");
        assertEq(MultiVault($.vault).asset(), $.oft, "Asset mismatch");

        console2.log("Target Core: %s", $.targetCore);
    }
}
