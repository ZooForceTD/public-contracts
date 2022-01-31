// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "../sharedDependencies/ZooForceERC721Pausable.sol";

abstract contract AnimalMinteableERC721 is ZooForceERC721Pausable{

    
    /*** DATA TYPES ***/
    struct Animal {

        // id of the Animal
        uint256 natureCode;

        // The timestamp from the block when this Animal came into existence.
        uint256 birthMoment;
    }

    /*** STORAGE ***/
    /// @dev An array containing the Animal struct for all ZooNFTs in existence. The ID
    ///  of each Animal is actually an index into this array. Note that ID 0 is a non existent Animal.
    Animal[] Animals;

    /**
     * @dev Mints `ZooNFTID` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `ZooNFTID` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mintZooNFT(address to, uint256 ZooNFTID, uint256 natureCode) internal override {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(ZooNFTID), "ERC721: token already minted");
        
        Animal memory _Animal = Animal({
            natureCode: natureCode,
            birthMoment: block.timestamp
        });
        
        Animals.push(_Animal);
        
        emit Birth(to, ZooNFTID, _Animal.natureCode);

        _beforeTokenTransfer(address(0), to, ZooNFTID);

        _holderTokens[to].add(ZooNFTID);

        _tokenOwners.set(ZooNFTID, to);
        

        emit Transfer(address(0), to, ZooNFTID);
    }

}