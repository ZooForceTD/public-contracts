// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../sharedDependencies/ZooForceERC721Pausable.sol";

abstract contract AccessoryMinteableERC721 is ZooForceERC721Pausable{

    
    /*** DATA TYPES ***/
    struct Accessory {

        // id of the Accessory
        uint256 natureCode;

        // The timestamp from the block when this Accessory came into existence.
        uint256 birthMoment;
    }

    /*** STORAGE ***/
    /// @dev An array containing the Accessory struct for all Accessories in existence. The ID
    ///  of each Accessory is actually an index into this array. Note that ID 0 is a non existent Accessory.
    Accessory[] Accessories;

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
        
        Accessory memory _Accessory = Accessory({
            natureCode: natureCode,
            birthMoment: block.timestamp
        });
        
        Accessories.push(_Accessory);
        
        emit Birth(to, ZooNFTID, _Accessory.natureCode);

        _beforeTokenTransfer(address(0), to, ZooNFTID);

        _holderTokens[to].add(ZooNFTID);

        _tokenOwners.set(ZooNFTID, to);
        

        emit Transfer(address(0), to, ZooNFTID);
    }

    function _mintZooNFTDeploymentBatch(address to, uint256[4] memory natureCodes, uint256 firstID) internal {
        // require(to != address(0), "ERC721: mint to the zero address");
        
        uint256 timeNow = block.timestamp;
        uint256 length = natureCodes.length;

        for(uint256 i = 0; i<length;i++){           
        require(!_exists(firstID+i), "ERC721: token already minted");

            Accessory memory _Accessory = Accessory({
                natureCode: natureCodes[i],
                birthMoment: timeNow
            });
            
            Accessories.push(_Accessory);
            
            emit Birth(to, firstID+i, _Accessory.natureCode);

            _holderTokens[to].add(firstID+i);

            _tokenOwners.set(firstID+i, to);

        }       
    }
}