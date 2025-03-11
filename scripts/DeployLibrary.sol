// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../src/oft/MellowOFT.sol";
import "../src/oft/MellowOFTAdapter.sol";

import "@openzeppelin/contracts/utils/Create2.sol";

library DeployLibrary {
    function computeOFTAdapterAddress(
        address token,
        address lzEndpoint,
        address delegate,
        bytes32 salt,
        address deployer
    ) internal view returns (address) {
        return Create2.computeAddress(
            salt,
            keccak256(abi.encodePacked(type(MellowOFTAdapter).creationCode, abi.encode(token, lzEndpoint, delegate))),
            deployer
        );
    }

    function computeOFTAddress(
        string memory name,
        string memory symbol,
        address lzEndpoint,
        address delegate,
        bytes32 salt,
        address deployer
    ) internal view returns (address) {
        return Create2.computeAddress(
            salt,
            keccak256(abi.encodePacked(type(MellowOFT).creationCode, abi.encode(name, symbol, lzEndpoint, delegate))),
            deployer
        );
    }

    function deployOFTAdapter(address token, address lzEndpoint, address delegate, bytes32 salt)
        internal
        returns (address)
    {
        return Create2.deploy(
            0, salt, abi.encodePacked(type(MellowOFTAdapter).creationCode, abi.encode(token, lzEndpoint, delegate))
        );
    }

    function deployOFT(string memory name, string memory symbol, address lzEndpoint, address delegate, bytes32 salt)
        internal
        returns (address)
    {
        return Create2.deploy(
            0, salt, abi.encodePacked(type(MellowOFT).creationCode, abi.encode(name, symbol, lzEndpoint, delegate))
        );
    }
}
