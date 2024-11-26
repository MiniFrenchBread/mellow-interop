// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "@stargate-v2/interfaces/IStargate.sol";

import "@layerzero-v2/evm/oapp/contracts/oapp/OApp.sol";
import "@layerzero-v2/evm/oapp/contracts/oapp/OAppCore.sol";
import "@layerzero-v2/evm/oapp/contracts/oapp/OAppReceiver.sol";
import "@layerzero-v2/evm/oapp/contracts/oapp/libs/OptionsBuilder.sol";

import "@layerzero-v2/evm/oapp/contracts/oft/OFT.sol";
import "@layerzero-v2/evm/oapp/contracts/oft/OFTAdapter.sol";
import "@layerzero-v2/evm/oapp/contracts/oft/interfaces/IOFT.sol";
import "@layerzero-v2/evm/oapp/contracts/oft/libs/OFTComposeMsgCodec.sol";
import "@layerzero-v2/evm/oapp/contracts/oft/libs/OFTMsgCodec.sol";

struct LayerZeroData {
    string name;
    string symbol;
    address endpoint;
    address stargate;
    address transmitter;
    address vaultOFTL2;
    address lockBoxL2;
    address oftAdapterL1;
    address underlying;
    uint32 srcEid;
    uint32 dstEid;
}
