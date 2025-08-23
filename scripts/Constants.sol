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
    uint256 public constant BSC_TESTNET_CHAINID = 97;
    uint256 public constant BSC_CHAINID = 56;
    uint256 public constant MANTA_CHAINID = 169;

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
        } else if (chainId == BSC_TESTNET_CHAINID) {
            return 40102;
        } else if (chainId == BSC_CHAINID) {
            return 30102;
        } else if (chainId == MANTA_CHAINID) {
            return 30217;
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
        } else if (chainId == BSC_TESTNET_CHAINID) {
            return 0x6EDCE65403992e310A62460808c4b910D972f10f;
        } else if (chainId == BSC_CHAINID) {
            return 0x1a44076050125825900e736c501f859c50fE728c;
        } else if (chainId == MANTA_CHAINID) {
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
        } else if (chainId == BSC_TESTNET_CHAINID) {
            return 0x55f16c442907e86D764AFdc2a07C2de3BdAc8BB7;
        } else if (chainId == BSC_CHAINID) {
            return 0x9F8C645f2D0b2159767Bd6E0839DE4BE49e823DE;
        } else if (chainId == MANTA_CHAINID) {
            return 0xD1654C656455E40E2905E96b6B91088AC2B362a2;
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
        } else if (chainId == BSC_TESTNET_CHAINID) {
            return 0x188d4bbCeD671A7aA2b5055937F79510A32e9683;
        } else if (chainId == BSC_CHAINID) {
            return 0xB217266c3A98C8B2709Ee26836C98cf12f6cCEC1;
        } else if (chainId == MANTA_CHAINID) {
            return 0xC1EC25A9e8a8DE5Aa346f635B33e5B74c4c081aF;
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
        } else if (sourceEndpointId == endpointId(BSC_TESTNET_CHAINID)) {
            if (block.chainid == BSC_TESTNET_CHAINID) {
                address[] memory dvns = new address[](2);
                dvns[0] = 0x0eE552262f7B562eFcED6DD4A7e2878AB897d405; // LayerZero labs
                dvns[1] = 0x35fa068eC18631719A7f6253710Ba29aB5C5F3b7; // BWare
                return dvns;
            } else if (block.chainid == HOLESKY_CHAINID) {
                address[] memory dvns = new address[](2);
                dvns[0] = 0x3E43f8ff0175580f7644DA043071c289DDf98118; // LayerZero labs
                dvns[1] = 0xD0D47C34937DdbeBBe698267a6BbB1dacE51198D; // BWare
                return dvns;
            }
        } else if (sourceEndpointId == endpointId(BSC_CHAINID)) {
            if (block.chainid == BSC_CHAINID) {
                address[] memory dvns = new address[](2);
                dvns[0] = 0xfD6865c841c2d64565562fCc7e05e619A30615f0; // LayerZero labs
                dvns[1] = 0xfE1cD27827E16b07E61A4AC96b521bDB35e00328; // BWare
                return dvns;
            } else if (block.chainid == ETHEREUM_CHAINID) {
                address[] memory dvns = new address[](2);
                dvns[0] = 0x589dEDbD617e0CBcB916A9223F4d1300c294236b; // LayerZero labs
                dvns[1] = 0x7a23612F07d81F16B26cF0b5a4C3eca0E8668df2; // BWare
                return dvns;
            }
        } else if (sourceEndpointId == endpointId(MANTA_CHAINID)) {
            if (block.chainid == MANTA_CHAINID) {
                address[] memory dvns = new address[](2);
                dvns[0] = 0x31F748a368a893Bdb5aBB67ec95F232507601A73; // Horizen
                dvns[1] = 0xA09dB5142654e3eB5Cf547D66833FAe7097B21C3; // LayerZero labs
                return dvns;
            } else if (block.chainid == ETHEREUM_CHAINID) {
                address[] memory dvns = new address[](2);
                dvns[0] = 0x380275805876Ff19055EA900CDb2B46a94ecF20D; // Horizen
                dvns[1] = 0x589dEDbD617e0CBcB916A9223F4d1300c294236b; // LayerZero labs
                return dvns;
            }
        }
        revert("Unsupported chain");
    }

    function manta(uint256 chainId) internal pure returns (address) {
        if (chainId == MANTA_CHAINID) {
            return 0x95CeF13441Be50d20cA4558CC0a27B601aC544E5;
        }
        revert("Unsupported chain");
    }

    function manta() internal view returns (address) {
        return manta(block.chainid);
    }

    function cyc(uint256 chainId) internal pure returns (address) {
        if (chainId == BSC_TESTNET_CHAINID) {
            return 0xD944A5e7E9D22F04C57f6aa8aD45Fb51D35F6920;
        } else if (chainId == BSC_CHAINID) {
            return 0x5845684b49aEf79A5c0F887f50401C247dca7AC6;
        }
        revert("Unsupported chain");
    }

    function cyc() internal view returns (address) {
        return cyc(block.chainid);
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

    function MANTA_TARGET_VAULT_ADMIN() internal pure returns (address) {
        return 0x0e5c716aA17106E6f6B74b2c0E1A015B643CE308;
    }

    function MANTA_TARGET_VAULT_PROXY_ADMIN() internal pure returns (address) {
        return 0xD4aFEe5cCe62128F3ACb67202e7Ae85fD3888f2A;
    }

    function MANTA_TARGET_CURATOR() internal pure returns (address) {
        return 0xBEE16D4331B0AD6aa60E07bA55427b56E0f578fb;
    }

    function MANTA_TARGET_CURATOR_OPERATOR() internal pure returns (address) {
        return 0xf47aE7d4bb095B0aafF59f3849346d39F770C8E3;
    }

    function MANTA_SOURCE_VAULT_ADMIN() internal pure returns (address) {
        return 0xdfCD6a517c86EdE52EF9C7f34ad9E918943ECe67;
    }

    function MANTA_SOURCE_VAULT_PROXY_ADMIN() internal pure returns (address) {
        return 0x30a7C7726dBA087C9af3547BDe7b2953DFdf06bB;
    }

    function MANTA_SOURCE_CURATOR() internal pure returns (address) {
        return 0x175427A2BDa468293eC2F5beE81060C1bd5D586e;
    }

    function MANTA_SOURCE_CURATOR_OPERATOR() internal pure returns (address) {
        return 0xf47aE7d4bb095B0aafF59f3849346d39F770C8E3;
    }

    function MANTA_SOURCE_ORACLE_UPDATER() internal pure returns (address) {
        return 0x9C807F6f6D785e31f4AF84722cd5097AB5A87d78;
    }

    function BSC_TESTNET_VAULT_ADMIN() internal pure returns (address) {
        return 0x27051Af764F55A4A8E6E3Eb1507c43E116B5826c;
    }

    function BSC_TESTNET_VAULT_PROXY_ADMIN() internal pure returns (address) {
        return 0x94D9358C32965dBaA42f1a178C539ED8F9B2ac61;
    }

    function HOLESKY_CYCLE_VAULT_ADMIN() internal pure returns (address) {
        return 0xC6255428adec8a692e233b311A95cB74DeBDeA22;
    }

    function HOLESKY_CYCLE_VAULT_PROXY_ADMIN() internal pure returns (address) {
        return 0xfCF94C817924998025115727Ebdc2962ee62Cb60;
    }

    function CYCLE_TESTNET_CURATOR() internal pure returns (address) {
        return 0x59D609BAa4245aEe8988346ADaA884eb461e02c5;
    }

    function CYCLE_MAINNET_CURATOR() internal pure returns (address) {
        return 0x759D4335cb712aa188935C2bD3Aa6D205aC61305;
    }

    function CYCLE_MAINNET_VAULT_ADMIN() internal pure returns (address) {
        return 0xE47EaC8C81FF1157360E3508eDA0D31824775E47;
    }

    function CYCLE_MAINNET_VAULT_PROXY_ADMIN() internal pure returns (address) {
        return 0x0CF4a2Db7734aABffD15b34fbe8A760B4EEEB9F4;
    }

    function sendGas() internal pure returns (uint128) {
        return 150000;
    }
}
