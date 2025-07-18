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
    uint256 public constant LISK_CHAINID = 1135;
    uint256 public constant FRAX_CHAINID = 252;

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
        } else if (chainId == LISK_CHAINID) {
            return 30321;
        } else if (chainId == FRAX_CHAINID) {
            return 30255;
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
        } else if (chainId == LISK_CHAINID) {
            return 0x6F475642a6e85809B1c36Fa62763669b1b48DD5B;
        } else if (chainId == FRAX_CHAINID) {
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
        } else if (chainId == LISK_CHAINID) {
            return 0xC39161c743D0307EB9BCc9FEF03eeb9Dc4802de7;
        } else if (chainId == FRAX_CHAINID) {
            return 0x377530cdA84DFb2673bF4d145DCF0C4D7fdcB5b6;
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
        } else if (chainId == LISK_CHAINID) {
            return 0xe1844c5D63a9543023008D332Bd3d2e6f1FE1043;
        } else if (chainId == FRAX_CHAINID) {
            return 0x8bC1e36F015b9902B54b1387A4d733cebc2f5A4e;
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
        } else if (chainId == LISK_CHAINID) {
            return 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
        }
        revert("Unsupported chain");
    }

    function requiredDVNs(uint32 sourceEndpointId) internal view returns (address[] memory) {
        if (sourceEndpointId == endpointId(FRAX_CHAINID)) {
            if (block.chainid == FRAX_CHAINID) {
                address[] memory dvns = new address[](2);
                dvns[0] = 0x26cD5aBaDf7eC3f0F02b48314bfcA6b2342cddD4; // Frax
                dvns[1] = 0xcCE466a522984415bC91338c232d98869193D46e; // LayerZero labs
                return dvns;
            } else if (block.chainid == ETHEREUM_CHAINID) {
                address[] memory dvns = new address[](2);
                dvns[0] = 0x38654142F5E672Ae86a1b21523AAfC765E6A1e08; // Frax
                dvns[1] = 0x589dEDbD617e0CBcB916A9223F4d1300c294236b; // LayerZero labs
                return dvns;
            }
        }
        revert("Unsupported chain");
    }

    function frax(uint256 chainId) internal pure returns (address) {
        if (chainId == FRAX_CHAINID) {
            return 0xFc00000000000000000000000000000000000002;
        }
        revert("Unsupported chain");
    }

    function frax() internal view returns (address) {
        return frax(block.chainid);
    }

    function mbtc(uint256 chainId) internal pure returns (address) {
        if (chainId == LISK_CHAINID) {
            return 0x9BFA177621119e64CecbEabE184ab9993E2ef727;
        }
        revert("Unsupported chain");
    }

    function mbtc() internal view returns (address) {
        return mbtc(block.chainid);
    }

    function lsk(uint256 chainId) internal pure returns (address) {
        if (chainId == LISK_CHAINID) {
            return 0xac485391EB2d7D88253a7F1eF18C37f4242D1A24;
        }
        revert("Unsupported chain");
    }

    function lsk() internal view returns (address) {
        return lsk(block.chainid);
    }

    function wsteth() internal view returns (address) {
        return wsteth(block.chainid);
    }

    function LISK_ADMIN() internal pure returns (address) {
        return 0xa62243c7a36e74d8280781242a3B0e019ce74E64;
    }

    function LISK_PROXY_ADMIN() internal pure returns (address) {
        return 0xC7e8b00a61adB658c49D2d8a377FC44572e9ECb5;
    }

    function LISK_ORACLE_UPDATER() internal pure returns (address) {
        return 0x62339BF5c4EB32EFAC9482F0277D68957A822641;
    }

    function LISK_CURATOR_ADMIN() internal pure returns (address) {
        return 0xE86399fE6d7007FdEcb08A2ee1434Ee677a04433;
    }

    function LISK_CURATOR_OPERATOR() internal pure returns (address) {
        return 0x5DD19228DC1b6EEaFF0BC649e25f83cc957B92Ed;
    }

    function ETHEREUM_ADMIN() internal pure returns (address) {
        return 0xa62243c7a36e74d8280781242a3B0e019ce74E64;
    }

    function ETHEREUM_PROXY_ADMIN() internal pure returns (address) {
        return 0xC7e8b00a61adB658c49D2d8a377FC44572e9ECb5;
    }

    function ETHEREUM_CURATOR_ADMIN() internal pure returns (address) {
        return 0xE86399fE6d7007FdEcb08A2ee1434Ee677a04433;
    }

    function ETHEREUM_CURATOR_OPERATOR() internal pure returns (address) {
        return 0x5DD19228DC1b6EEaFF0BC649e25f83cc957B92Ed;
    }

    function FRAX_ADMIN() internal pure returns (address) {
        return 0xD6dCc17AF74217356cbA56aa485b3f0fe8437896;
    }

    function FRAX_PROXY_ADMIN() internal pure returns (address) {
        return 0xd2D2a9d446591833b32b3FAD2f2b3810Cd98b34f;
    }

    function FRAX_ORACLE_UPDATER() internal pure returns (address) {
        return 0xF32fD742608c237D5a377838fa69837584cA9676;
    }

    function FRAX_CURATOR_ADMIN() internal pure returns (address) {
        return 0xBE8e7c5E750124eA690E387eB6eF32e723fD051d;
    }

    function FRAX_CURATOR_OPERATOR() internal pure returns (address) {
        return 0x5DD19228DC1b6EEaFF0BC649e25f83cc957B92Ed;
    }

    function sendGas() internal pure returns (uint128) {
        return 150000;
    }
}
