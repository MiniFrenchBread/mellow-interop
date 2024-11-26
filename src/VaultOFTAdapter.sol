// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.25;

import "./interfaces/LayerZeroImports.sol";

contract VaultOFTAdapter is OFTAdapter {
    using SafeERC20 for IERC20;

    constructor(address _underlying, address _lzEndpoint, address _delegate)
        OFTAdapter(_underlying, _lzEndpoint, _delegate)
        Ownable(_delegate)
    {}

    /**
     * @dev Burns tokens from the sender's specified balance, ie. pull method.
     * @param _from The address to debit from.
     * @param _amountLD The amount of tokens to send in local decimals. May be equals to zero
     * @param _minAmountLD The minimum amount to send in local decimals.
     * @param _dstEid The destination chain ID.
     * @return amountSentLD The amount sent in local decimals.
     * @return amountReceivedLD The amount received in local decimals on the remote.
     *
     * @dev msg.sender will need to approve this _amountLD of tokens to be locked inside of the contract.
     * @dev WARNING: The default OFTAdapter implementation assumes LOSSLESS transfers, ie. 1 token in, 1 token out.
     * IF the 'innerToken' applies something like a transfer fee, the default will NOT work...
     * a pre/post balance check will need to be done to calculate the amountReceivedLD.
     */
    function _debit(address _from, uint256 _amountLD, uint256 _minAmountLD, uint32 _dstEid)
        internal
        virtual
        override
        returns (uint256 amountSentLD, uint256 amountReceivedLD)
    {
        if (_amountLD > 0) {
            (amountSentLD, amountReceivedLD) = _debitView(_amountLD, _minAmountLD, _dstEid);
            /// @dev Lock tokens by moving them into this contract from the caller.
            innerToken.safeTransferFrom(_from, address(this), amountSentLD);
        }
    }
}
