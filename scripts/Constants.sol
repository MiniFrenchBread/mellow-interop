// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import {ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {
    EnforcedOptionParam,
    IOAppOptionsType3
} from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppOptionsType3.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {UlnConfig} from "@layerzerolabs/lz-evm-protocol-v2/../messagelib/contracts/uln/UlnBase.sol";
import {
    IMessageLibManager,
    SetConfigParam
} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";

import "../src/core/SourceCore.sol";
import "../src/core/TargetCore.sol";
import "../src/oft/MellowOFT.sol";
import "../src/oft/MellowOFTAdapter.sol";
import "../src/utils/Delegator.sol";

library Constants {
    uint256 public constant ETHEREUM_CHAINID = 1;
    uint256 public constant HOLESKY_CHAINID = 17000;
    uint256 public constant SEPOLIA_CHAINID = 11155111;
    uint256 public constant OPTIMISM_CHAINID = 10;
    uint256 public constant ARBITRUM_CHAINID = 42161;

    function endpointId(uint256 chainId) internal pure returns (uint32) {
        if (chainId == HOLESKY_CHAINID) {
            return 40217;
        } else if (chainId == ETHEREUM_CHAINID) {
            return 30101;
        } else if (chainId == SEPOLIA_CHAINID) {
            return 40161;
        } else if (chainId == OPTIMISM_CHAINID) {
            return 30111;
        } else if (chainId == ARBITRUM_CHAINID) {
            return 30110;
        }
        revert("Unsupported chain");
    }

    function endpointId() internal view returns (uint32) {
        return endpointId(block.chainid);
    }

    function endpointV2(uint256 chainId) internal pure returns (address) {
        if (chainId == HOLESKY_CHAINID) {
            return 0x6EDCE65403992e310A62460808c4b910D972f10f;
        } else if (chainId == ETHEREUM_CHAINID) {
            return 0x1a44076050125825900e736c501f859c50fE728c;
        } else if (chainId == SEPOLIA_CHAINID) {
            return 0x6EDCE65403992e310A62460808c4b910D972f10f;
        } else if (chainId == OPTIMISM_CHAINID) {
            return 0x1a44076050125825900e736c501f859c50fE728c;
        } else if (chainId == ARBITRUM_CHAINID) {
            return 0x1a44076050125825900e736c501f859c50fE728c;
        }
        revert("Unsupported chain");
    }

    function endpointV2() internal view returns (address) {
        return endpointV2(block.chainid);
    }

    function sendLibrary(uint256 chainId) internal pure returns (address) {
        if (chainId == HOLESKY_CHAINID) {
            return 0x21F33EcF7F65D61f77e554B4B4380829908cD076;
        } else if (chainId == ETHEREUM_CHAINID) {
            return 0xbB2Ea70C9E858123480642Cf96acbcCE1372dCe1;
        } else if (chainId == SEPOLIA_CHAINID) {
            return 0xcc1ae8Cf5D3904Cef3360A9532B477529b177cCE;
        } else if (chainId == OPTIMISM_CHAINID) {
            return 0x1322871e4ab09Bc7f5717189434f97bBD9546e95;
        } else if (chainId == ARBITRUM_CHAINID) {
            return 0x975bcD720be66659e3EB3C0e4F1866a3020E493A;
        }
        revert("Unsupported chain");
    }

    function sendLibrary() internal view returns (address) {
        return sendLibrary(block.chainid);
    }

    function receiveLibrary(uint256 chainId) internal pure returns (address) {
        if (chainId == HOLESKY_CHAINID) {
            return 0xbAe52D605770aD2f0D17533ce56D146c7C964A0d;
        } else if (chainId == ETHEREUM_CHAINID) {
            return 0xc02Ab410f0734EFa3F14628780e6e695156024C2;
        } else if (chainId == SEPOLIA_CHAINID) {
            return 0xdAf00F5eE2158dD58E0d3857851c432E34A3A851;
        } else if (chainId == OPTIMISM_CHAINID) {
            return 0x3c4962Ff6258dcfCafD23a814237B7d6Eb712063;
        } else if (chainId == ARBITRUM_CHAINID) {
            return 0x7B9E184e07a6EE1aC23eAe0fe8D6Be2f663f05e6;
        }
        revert("Unsupported chain");
    }

    function receiveLibrary() internal view returns (address) {
        return receiveLibrary(block.chainid);
    }

    function wsteth(uint256 chainId) internal pure returns (address) {
        if (chainId == HOLESKY_CHAINID) {
            return 0x8d09a4502Cc8Cf1547aD300E066060D043f6982D;
        } else if (chainId == ETHEREUM_CHAINID) {
            return 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
        } else if (chainId == SEPOLIA_CHAINID) {
            return 0xB82381A3fBD3FaFA77B3a7bE693342618240067b;
        } else if (chainId == OPTIMISM_CHAINID) {
            return 0x1F32b1c2345538c0c6f582fCB022739c4A194Ebb;
        } else if (chainId == ARBITRUM_CHAINID) {
            return 0x5979D7b546E38E414F7E9822514be443A4800529;
        }
        revert("Unsupported chain");
    }

    function wsteth() internal view returns (address) {
        return wsteth(block.chainid);
    }

    function sendGas() internal pure returns (uint128) {
        return 150000;
    }
}
