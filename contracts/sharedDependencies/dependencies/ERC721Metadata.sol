// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
abstract contract ERC721Metadata {
    
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

        /**
    * @dev See {IERC721Enumerable-name}.
     */
    function name() public view  returns (string memory) {
        return _name;    
    }
    
    /**
    * @dev See {IERC721Enumerable-symbol}.
     */
    function symbol() public view  returns (string memory) {
        return _symbol;
    }

    constructor(string memory _newName, string memory _newSymbol) internal{
        _name = _newName;
        _symbol=_newSymbol;
    }
    
}