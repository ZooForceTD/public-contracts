// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
import "./ZooForceERC721.sol";
import "./extensions/Pausable.sol";

abstract contract ZooForceERC721Pausable is ZooForceERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}