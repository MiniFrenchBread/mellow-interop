// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../core/TargetCore.sol";
import {ILayerZeroEndpointV2, IOAppCore} from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppCore.sol";
import {
    IMultiVaultStorage,
    IWithdrawalQueue as IMultiVaultQueue,
    MultiVault
} from "@mellow-finance/simple-lrt/vaults/MultiVault.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

interface IClaimer {
    function multiAcceptAndClaim(
        address multiVault,
        uint256[] calldata subvaultIndices,
        uint256[][] calldata indices,
        address recipient,
        uint256 maxAssets
    ) external returns (uint256 assets);
}

contract TargetHelper {
    function getNonces(TargetCore core) public view returns (uint256 inboundNonce, uint256 outboundNonce) {
        ILayerZeroEndpointV2 endpoint = IOAppCore(address(core.oft())).endpoint();
        uint32 sourceEid = core.sourceEndpointId();
        bytes32 sourceCore = core.sourceCoreAddress();
        inboundNonce = endpoint.inboundNonce(address(core), sourceEid, sourceCore);
        outboundNonce = endpoint.outboundNonce(address(core), sourceEid, sourceCore);
    }

    /// @dev only 1 Symbiotic subvault is supported
    function getAmounts(TargetCore core, uint256 redeemDemandAssets)
        public
        view
        returns (uint256 pushAssets, bytes memory claimData, uint256 redeemShares, uint256 depositableAssets)
    {
        MultiVault vault = MultiVault(address(core.vault()));
        uint256 pendingAssets = 0;
        uint256 claimableAssets = 0;
        if (vault.subvaultsCount() != 0) {
            require(vault.subvaultsCount() == 1, "TargetHelper: only one subvault supported");
            address queue = vault.subvaultAt(0).withdrawalQueue;
            pendingAssets = IMultiVaultQueue(queue).pendingAssetsOf(address(core));
            claimableAssets = IMultiVaultQueue(queue).claimableAssetsOf(address(core));
            if (claimableAssets != 0) {
                claimData = abi.encodeCall(
                    IClaimer.multiAcceptAndClaim,
                    (address(vault), new uint256[](1), new uint256[][](1), address(core), type(uint256).max)
                );
            }
        }

        if (redeemDemandAssets > 0) {
            IMellowOFT oft = core.oft();
            uint256 liquidAssets = oft.balanceOf(address(core)) + claimableAssets;
            pushAssets = Math.min(redeemDemandAssets, liquidAssets);
            if (pendingAssets + liquidAssets < redeemDemandAssets) {
                uint256 requiredAssets = redeemDemandAssets - liquidAssets - pendingAssets;
                redeemShares = Math.min(vault.previewWithdraw(requiredAssets), vault.balanceOf(address(core)));
                uint256 vaultLiquidAssets = oft.balanceOf(address(vault));
                if (vaultLiquidAssets != 0) {
                    pushAssets = Math.min(redeemDemandAssets - pendingAssets, liquidAssets + vaultLiquidAssets);
                }
            } else {
                depositableAssets = liquidAssets > redeemDemandAssets ? liquidAssets - redeemDemandAssets : 0;
            }
        } else {
            depositableAssets = core.oft().balanceOf(address(core)) + claimableAssets;
        }
    }
}
