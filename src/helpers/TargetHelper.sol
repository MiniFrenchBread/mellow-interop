// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../core/TargetCore.sol";
import {ILayerZeroEndpointV2, IOAppCore} from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppCore.sol";
import {
    IDelegationManager,
    IEigenLayerWithdrawalQueue,
    IIsolatedEigenLayerVault
} from "@mellow-finance/simple-lrt/interfaces/queues/IEigenLayerWithdrawalQueue.sol";
import {
    IERC4626,
    IMultiVault,
    IMultiVaultStorage,
    IWithdrawalQueue as IMultiVaultQueue
} from "@mellow-finance/simple-lrt/interfaces/vaults/IMultiVault.sol";
import {Arrays} from "@openzeppelin/contracts/utils/Arrays.sol";
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

    function getQueuedAssets(IEigenLayerWithdrawalQueue queue, address core) public view returns (uint256 assets) {
        uint256[] memory withdrawalIndices;
        {
            (uint256 claimableAssets, uint256[] memory indices1, uint256[] memory indices2) =
                queue.getAccountData(address(core), type(uint256).max, 0, type(uint256).max, 0);
            assets = claimableAssets;
            withdrawalIndices = new uint256[](indices1.length + indices2.length);
            for (uint256 j = 0; j < indices1.length; j++) {
                withdrawalIndices[j] = indices1[j];
            }
            for (uint256 j = 0; j < indices2.length; j++) {
                withdrawalIndices[indices1.length + j] = indices2[j];
            }
            uint256 length = withdrawalIndices.length;
            if (length == 0) {
                return assets;
            }
            Arrays.sort(withdrawalIndices);
            uint256 iterator = 1;
            for (uint256 i = 1; i < length; i++) {
                if (withdrawalIndices[i] != withdrawalIndices[i - 1]) {
                    withdrawalIndices[iterator++] = withdrawalIndices[i];
                }
            }
            assembly {
                mstore(withdrawalIndices, iterator)
            }
        }
        uint256 shares = 0;
        for (uint256 i = 0; i < withdrawalIndices.length; i++) {
            (
                IDelegationManager.Withdrawal memory data,
                bool isClaimed,
                uint256 assets_,
                uint256 shares_,
                uint256 accountShares
            ) = queue.getWithdrawalRequest(withdrawalIndices[i], core);
            if (isClaimed) {
                assets += Math.mulDiv(assets_, accountShares, shares_);
            } else {
                shares += queue.convertScaledSharesToShares(data, accountShares, shares_);
            }
        }
        assets += IIsolatedEigenLayerVault(queue.isolatedVault()).sharesToUnderlyingView(queue.strategy(), shares);
    }

    function getTargetValue(TargetCore core) public view returns (uint256 assets) {
        IMellowOFT oft = core.oft();
        assets = oft.balanceOf(address(core));
        IMultiVault vault = IMultiVault(address(core.vault()));
        uint256 count = vault.subvaultsCount();
        IMultiVaultStorage.Subvault memory subvault;
        for (uint256 i = 0; i < count; i++) {
            subvault = vault.subvaultAt(i);
            if (subvault.withdrawalQueue == address(0)) {
                continue;
            }
            if (subvault.protocol == IMultiVaultStorage.Protocol.EIGEN_LAYER) {
                assets += getQueuedAssets(IEigenLayerWithdrawalQueue(subvault.withdrawalQueue), address(core));
            } else {
                assets += IMultiVaultQueue(subvault.withdrawalQueue).pendingAssetsOf(address(core));
                assets += IMultiVaultQueue(subvault.withdrawalQueue).claimableAssetsOf(address(core));
            }
        }
    }

    struct Stack {
        uint256 pendingAssets;
        uint256 subvaultCount;
        uint256[] subvaultIndices;
        uint256[][] withdrawalIndices;
        uint256 temp;
        uint256 claimableAssets;
        uint256 iterator;
    }

    function getAmounts(TargetCore core, uint256 redeemDemandAssets)
        public
        view
        returns (uint256 pushAssets, bytes memory claimData, uint256 redeemShares, uint256 depositableAssets)
    {
        Stack memory stack;
        IMultiVault vault = IMultiVault(address(core.vault()));
        {
            stack.subvaultCount = vault.subvaultsCount();
            stack.subvaultIndices = new uint256[](stack.subvaultCount);
            stack.withdrawalIndices = new uint256[][](stack.subvaultCount);
            stack.iterator = 0;
            IMultiVaultStorage.Subvault memory subvault;
            for (uint256 i = 0; i < stack.subvaultCount; i++) {
                subvault = vault.subvaultAt(i);
                address queue = subvault.withdrawalQueue;
                if (queue == address(0)) {
                    continue;
                }
                stack.pendingAssets += IMultiVaultQueue(queue).pendingAssetsOf(address(core));
                stack.temp = IMultiVaultQueue(queue).claimableAssetsOf(address(core));
                if (stack.temp != 0) {
                    stack.claimableAssets += stack.temp;
                    if (subvault.protocol == IMultiVaultStorage.Protocol.EIGEN_LAYER) {
                        /// @dev we assume that there are no depositors in EigenLayer vault other than the TargetCore.
                        (,, stack.withdrawalIndices[stack.iterator]) =
                            IEigenLayerWithdrawalQueue(queue).getAccountData(address(core), 0, 0, type(uint256).max, 0);
                    }
                    stack.subvaultIndices[stack.iterator++] = i;
                }
            }
            uint256[] memory subvaultIndices = stack.subvaultIndices;
            uint256[][] memory withdrawalIndices = stack.withdrawalIndices;
            uint256 iterator = stack.iterator;
            assembly {
                mstore(subvaultIndices, iterator)
                mstore(withdrawalIndices, iterator)
            }
            claimData = abi.encodeCall(
                IClaimer.multiAcceptAndClaim,
                (address(vault), subvaultIndices, withdrawalIndices, address(core), type(uint256).max)
            );
        }

        if (redeemDemandAssets > 0) {
            IMellowOFT oft = core.oft();
            uint256 liquidAssets = oft.balanceOf(address(core)) + stack.claimableAssets;
            pushAssets = Math.min(redeemDemandAssets, liquidAssets);
            if (stack.pendingAssets + liquidAssets < redeemDemandAssets) {
                uint256 requiredAssets = redeemDemandAssets - liquidAssets - stack.pendingAssets;
                redeemShares = Math.min(
                    IERC4626(address(vault)).previewWithdraw(requiredAssets),
                    IERC4626(address(vault)).balanceOf(address(core))
                );
                uint256 vaultLiquidAssets = oft.balanceOf(address(vault));
                if (vaultLiquidAssets != 0) {
                    pushAssets = Math.min(redeemDemandAssets - stack.pendingAssets, liquidAssets + vaultLiquidAssets);
                }
            } else {
                depositableAssets = liquidAssets > redeemDemandAssets ? liquidAssets - redeemDemandAssets : 0;
            }
            pushAssets = core.oft().removeDust(pushAssets);
        } else {
            depositableAssets = core.oft().balanceOf(address(core)) + stack.claimableAssets;
        }
    }

    function quotePushToSource(TargetCore core) public view returns (uint256) {
        return core.oft().quoteSend(
            SendParam({
                dstEid: core.sourceEndpointId(),
                to: core.sourceCoreAddress(),
                amountLD: 1 ether,
                minAmountLD: 0,
                extraOptions: new bytes(0),
                composeMsg: new bytes(0),
                oftCmd: new bytes(0)
            }),
            false
        ).nativeFee;
    }
}
