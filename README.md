# Interoperable Vaults

Interoperable Vaults facilitate cross‐chain restaking, allowing users to deposit assets on EVM networks and receive vault shares, which are then restaked on Ethereal mainnet. LayerZero’s OFT (Omnichain Fungible Token) is used for cross-chain messaging, with custom modifications to enable seamless deposit and withdrawal flows on L1&2s.

## Fraxtal

### Deployments

| Contract | Asset | Address |
|----------|-------|---------|
| SourceCore | FRAX | `0x24dD1eaBEad7b3cB07b7d162439ec0A4EEC703DF` |
| MellowOFTAdapter | FRAX | `0x24E6D68a553BA3146E10CDb06e9dB996Cea2bbBa` |
| TargetCore | FRAX | `0x6408a5261578E17f858ADD039dEb72E1952E9Fe9` |
| MellowOFT | FRAX | `0xf85932AcE734E3CF04b5c2a6Cb7B10f44014eCb9` |
| MultiVault | FRAX | `0x5B2099e204f22A0ccE3806fc2093713E2780D437` |

### Balance checker (FRAX Vault)

Address: `0x7603716BD8024e6B5275Fc98a88779D1370F3812`

#### Farm's data

| Key | Value |
|-----|-------|
| Name | rstFRAX |
| Symbol | rstFRAX |
| Decimals | 18 |
| URL | <https://app.mellow.finance/vaults/fraxtal-frax-vault> |
| Farm address | `0x24dD1eaBEad7b3cB07b7d162439ec0A4EEC703DF` |
| Source address | `0x24dD1eaBEad7b3cB07b7d162439ec0A4EEC703DF` |

#### Total liquidity calculation

Get the `FRAX` token balance of `0x24dD1eaBEad7b3cB07b7d162439ec0A4EEC703DF`.

#### Additional notes

As for interaction events, the farm (vault) is built as ERC4626, therefore:

- Deposit event: `emit Deposit(caller, receiver, assets, shares)` (hash: `0xdcbc1c05240f31ff3ad067ef1ee35ce4997762752e3a095284754544f4c709d7`)

- Withdraw event: `emit Withdraw(caller, receiver, owner, assets, shares)` (hash: `0xfbde797d201c681b91056529119e0b02407c7bb96a4a2c75c01fc9667232c8db`)

Address for listening to events: `0x24dD1eaBEad7b3cB07b7d162439ec0A4EEC703DF`
