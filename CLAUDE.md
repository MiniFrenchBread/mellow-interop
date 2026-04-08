# CLAUDE.md - mellow-interop

## Project Overview

Mellow Interop is a Solidity smart contract system for **cross-chain restaking vaults**. It allows users to deposit assets (e.g., W0G, wstETH, FRAX, CYC, MANTA, SolvBTC) on a "source" EVM chain and have those assets restaked into Mellow Finance MultiVault positions on a "target" chain (typically Ethereum mainnet). LayerZero's OFT (Omnichain Fungible Token) protocol handles cross-chain token transfers.

The source-chain vault is an ERC-4626 tokenized vault; users deposit an underlying asset and receive vault shares. An operator bot periodically bridges deposited assets to the target chain and deposits them into Mellow MultiVaults (which in turn restake into EigenLayer / Symbiotic). Withdrawals follow an epoch-based queue with a configurable delay to allow the operator time to unwind target-chain positions.

Built by Mellow Finance. Solidity 0.8.25, Foundry toolchain, Cancun EVM target.

## Architecture

### Two-Chain Model

Each deployment spans two chains:

- **Source chain** (where users deposit): 0G, Fraxtal, BSC, Manta, Lisk, etc.
- **Target chain** (where restaking happens): Ethereum mainnet (or Holesky/Sepolia for testnets)

### Core Contracts

| Contract | Chain | Purpose |
|---|---|---|
| `SourceCore` | Source | ERC-4626 vault where users deposit/mint. Manages withdrawal requests. Sends assets cross-chain via `pushToTarget()`. |
| `TargetCore` | Target | Receives bridged assets, deposits into MultiVault, redeems/claims from withdrawal queues, sends assets back via `pushToSource()`. |
| `MellowOFTAdapter` | Source | LayerZero OFT adapter that locks real tokens on source chain and sends cross-chain messages. Only callable by SourceCore. |
| `MellowOFT` | Target | LayerZero OFT token minted on target chain representing bridged assets. Used as the underlying token for MultiVault deposits. |
| `Oracle` | Source | Price oracle storing a `value` (shares-to-assets ratio, 1e18 scale). Updated by a privileged role. Has staleness check (`maxAge`). |
| `WithdrawalQueue` | Source | Epoch-based delayed withdrawal queue. Users request withdrawal; after epoch ends + `withdrawalDelay`, the queue can pull assets from SourceCore to fulfill claims. |
| `Delegator` | Both | Admin helper for LayerZero endpoint management (clear stuck messages, arbitrary calls). |
| `Collector` | Source | Read-only helper to query withdrawal request data for a user. |
| `SourceHelper` / `TargetHelper` | Respective | Read-only view helpers for nonces, value calculations, quote estimates, and rebalancing parameters. |
| `MellowInteropBalanceChecker` | Source | Batch balance checker normalizing vault share balances to 18-decimal underlying amounts. |

### Cross-Chain Flow

1. User calls `SourceCore.deposit(assets, receiver)` on source chain, receives vault shares.
2. Operator calls `SourceCore.pushToTarget()` -- bridges liquid assets via LayerZero OFT to TargetCore on target chain.
3. Operator calls `TargetCore.deposit(assets)` -- deposits OFT tokens into Mellow MultiVault (which restakes into EigenLayer/Symbiotic).
4. For withdrawals: user calls `SourceCore.requestWithdrawal(shares)`.
5. After epoch + delay, operator redeems/claims from MultiVault, calls `TargetCore.pushToSource(assets)` to bridge back.
6. `WithdrawalQueue.handleEpoch()` pulls assets from SourceCore to fulfill queued withdrawals.
7. User calls `WithdrawalQueue.claim(epoch, receiver)` to receive assets.

### Role-Based Access

**Source chain roles (on SourceCore):**
- `DEFAULT_ADMIN_ROLE` -- vault admin (multisig)
- `PUSH_ROLE` -- operator/bot that triggers cross-chain transfers
- `SET_LIMIT_ROLE` -- curator that manages deposit limits
- `SET_VALUE_ROLE` (on Oracle) -- oracle updater
- `SET_MAX_AGE_ROLE` (on Oracle) -- vault admin
- `SET_WITHDRAWAL_DELAY_ROLE` (on WithdrawalQueue) -- vault admin

**Target chain roles (on TargetCore):**
- `DEFAULT_ADMIN_ROLE` -- vault admin
- `DEPOSIT_ROLE`, `REDEEM_ROLE`, `CLAIM_ROLE`, `PUSH_ROLE` -- operator/bot

## Build and Test Commands

Requires: [Foundry](https://book.getfoundry.sh/) (`forge`, `cast`)

```bash
# Build
forge build                        # or: npm run compile

# Format
forge fmt ./src/** ./test/** ./scripts/**   # or: npm run prettier

# Run tests (requires MAINNET_RPC in .env for fork tests)
forge test -vvv --fork-url $MAINNET_RPC --fork-block-number 21900000
# or: npm run test:mainnet

# Contract sizes
forge build --sizes --force        # or: npm run sizes

# Coverage report (generates HTML in ./report/)
npm run coverage:report

# Source line counts
npm run scc:report
```

### Deployment Scripts

Each chain pair has its own script directory under `scripts/`. The workflow per deployment is:

1. `deploy:source:<chain-ids>` -- Deploy SourceCore proxy + MellowOFTAdapter on source chain
2. `deploy:target:<chain-ids>` -- Deploy TargetCore proxy + MellowOFT on target chain
3. `init:source:<chain-ids>` -- Initialize SourceCore (oracle, withdrawal queue, LZ config, roles)
4. `init:target:<chain-ids>` -- Initialize TargetCore (vault, claimer, LZ config, roles)
5. `script:source:<chain-ids>` / `script:target:<chain-ids>` -- Post-init configuration

Scripts read private keys and RPC URLs from `.env`. Use `npm run <script-name>` to execute.

### Environment Variables (.env)

Required for fork tests and deployments:
- `MAINNET_RPC` -- Ethereum mainnet RPC
- `HOT_DEPLOYER` -- Deployer private key (hex)
- `ETHERSCAN_API_KEY` -- For contract verification
- Chain-specific RPCs: `FRAX_RPC`, `BSC_RPC`, `BSC_TESTNET_RPC`, `HOLESKY_RPC`, `SEPOLIA_RPC`, `MANTA_RPC`, `GALILEO_RPC`, `OG_RPC`, `LISK_RPC`

## Important Directories and Files

```
src/
  core/
    SourceCore.sol          -- Main source-chain ERC-4626 vault
    SourceCoreStorage.sol   -- Storage layout for SourceCore
    TargetCore.sol          -- Main target-chain restaking manager
    TargetCoreStorage.sol   -- Storage layout for TargetCore
  oft/
    MellowOFT.sol           -- LayerZero OFT token (target chain)
    MellowOFTAdapter.sol    -- LayerZero OFT adapter (source chain)
  utils/
    Oracle.sol              -- Price oracle with staleness protection
    WithdrawalQueue.sol     -- Epoch-based withdrawal queue
    Delegator.sol           -- Admin helper for LZ endpoint ops
  helpers/
    SourceHelper.sol        -- Read-only source-chain view functions
    TargetHelper.sol        -- Read-only target-chain view functions
    Collector.sol           -- Withdrawal request data aggregator
    MellowInteropBalanceChecker.sol -- Batch balance checker
  interfaces/              -- All interface definitions

scripts/
  Constants.sol            -- Chain IDs, LZ endpoints, DVN addresses, token addresses
  common/                  -- Reusable deploy/init libraries
  0g-ethereum/             -- 0G mainnet <-> Ethereum mainnet deployment (W0G / aOG)
  sepolia-0g-test/         -- 0G Galileo testnet <-> Sepolia testnet deployment
  frax-ethereum/           -- Fraxtal <-> Ethereum (FRAX / rstFRAX)
  bsc-ethereum/            -- BSC <-> Ethereum (CYC)
  bsc-ethereum-solv/       -- BSC <-> Ethereum (SolvBTC)
  manta-ethereum/          -- Manta <-> Ethereum (MANTA)
  lisk-ethereum/           -- Lisk <-> Ethereum (wstETH, mBTC, LSK)
  bsc-testnet-holesky/     -- BSC Testnet <-> Holesky testnet
  helpers/                 -- Generic helper deployment script

test/
  IntegrationTest.t.sol    -- Full integration test with mock LZ endpoints
  SourceCore.t.sol         -- SourceCore unit tests
  acceptance/              -- On-chain acceptance tests (run against live forks)
  helpers/                 -- Balance checker tests

lib/                       -- Git submodule dependencies
  forge-std/               -- Foundry test framework
  openzeppelin-contracts/  -- OpenZeppelin v5
  openzeppelin-contracts-upgradeable/
  layerzero-v1/            -- LayerZero v1 (legacy)
  layerzero-v2/            -- LayerZero v2 protocol
  devtools/                -- LayerZero OFT/OApp dev tools
  simple-lrt/              -- Mellow Finance MultiVault / simple-lrt (multi-vault branch)
  solidity-bytes-utils/

audits/                    -- Security audit reports (Decurity, Nethermind, March 2025)
foundry.toml               -- Foundry config (Cancun EVM, optimizer 200 runs)
package.json               -- npm scripts for build/test/deploy
remappings.txt             -- Solidity import remappings
```

## Active Deployments (0G Ecosystem)

**0G Mainnet (chain 16661) <-> Ethereum Mainnet:**
- Asset: W0G (Wrapped 0G token) at `0x1Cd0690fF9a693f5EF2dD976660a8dAFc81A109c`
- SourceCore (aOG / Ascend Staked OG): `0x4B3c2f55fa67679b382c979A082Df1B32079B4cB`
- TargetCore: `0xd46E464c82643e6937838A94d40FD8D014A2EA26`
- MellowOFTAdapter: `0x28eCbDbf7AA257A42D786409c7a27B9CE92aA1fF`
- MellowOFT (0G OFT): `0xE42215BD71E190b3864267569c2f66077260EaE4`
- Target MultiVault: `0x0Ff6ea4CAD58b9e54535Ae1eA2452cdbfFb9bfaB`
- Oracle: `0x8f7b85432F7BB3534ca34E42c215146Db47a4Eab`
- WithdrawalQueue: `0x10A98a5344742308744Bd59829786584A12C1146`

## Relationship to Other Repos

### mellow-interop-bot (companion)
Python bot (`/Users/wangfan/Project/0g/mellow-interop-bot`) that automates the operator workflow:
- **Oracle monitoring**: Tracks oracle staleness across deployments, sends Telegram alerts when updates are needed.
- **Operator bot** (`operator_bot.py`): Executes the cross-chain rebalancing cycle -- pushes assets to target, deposits into MultiVault, redeems/claims when withdrawals are pending, pushes assets back to source.
- **Safe Global integration**: Proposes multisig transactions for oracle updates and admin operations.
- **Epoch handling**: Calls `WithdrawalQueue.handleEpoch()` when epochs mature (also done in `run_bot.sh`).
- **Run loop** (`run_bot.sh`): Scheduler that orchestrates ascend (restaking contract calls), operator bot (every 2h), monitoring (daily), and epoch handling (continuous).
- Reads ABI and deployment addresses from its own `config.json` which mirrors the contract addresses from this repo.

### 0g-restaking-contracts
The `run_bot.sh` in mellow-interop-bot calls `ascend.sh` from the 0g-restaking-contracts repo every 2 weeks to manage the restaking lifecycle on the 0G chain side.

### 0g-chain-v2 / 0g-geth / 0g-reth
The 0G blockchain infrastructure. This repo deploys SourceCore on the 0G EVM chain (chain ID 16661), which runs on these execution/consensus clients. The W0G token is the native wrapped token on 0G.

### simple-lrt (git submodule)
Mellow Finance's MultiVault / simple-lrt library (used as a dependency). TargetCore deposits into MultiVault instances which handle the actual restaking into EigenLayer and Symbiotic protocols on Ethereum.
