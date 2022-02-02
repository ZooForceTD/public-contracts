// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "./extensions/Context.sol";
import "./extensions/SafeMath.sol";
import "./extensions/EnumerableSet.sol";
import "./extensions/EnumerableMap.sol";
import "./extensions/Address.sol";
import "./dependencies/ERC165.sol";
import "./dependencies/IERC721.sol";
import "./dependencies/ERC721Metadata.sol";
import "./dependencies/IERC721Receiver.sol";
import "./dependencies/IERC721Enumerable.sol";

abstract contract ZooForceERC721 is Context, ERC165, IERC721, IERC721Enumerable, ERC721Metadata {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    /// @dev The Birth event is fired whenever a new ZooNFT comes into existence.
    event Birth(address owner, uint256 ZooNFTID, uint256 natureCode);


    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 internal constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) internal _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap internal _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) internal _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) internal _operatorApprovals;
    
    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 internal constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 internal constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 internal constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor () public {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _holderTokens[owner].length();
    }

    // function natureCodesOf(address owner) public view override returns (uint256[] memory) {
    //     require(owner != address(0), "ERC721: balance query for the zero address");
    //     uint256[] memory natureCodes;
    //     uint256 arrayLength = _holderTokens[owner].length();
    //     for(uint256 i = 0;i <arrayLength; i++){
    //         natureCodes[i] = _holderTokens[owner].at(i);
    //     }
    //     return natureCodes;
    // }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 ZooNFTID) public view override returns (address) {
        return _tokenOwners.get(ZooNFTID, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return _holderTokens[owner].at(index);
    }
    
    /**
     * @dev See {IERC721Enumerable-tokenOfOwner}.
     */
    function tokenOfOwner(address owner) public view override returns (uint256[] memory) {
        uint256[] memory tokens = new uint256[](_holderTokens[owner].length());
        for(uint i=0; i< _holderTokens[owner].length(); i++) {
            tokens[i] = _holderTokens[owner].at(i);
        }
        return tokens;
    }


    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        // _tokenOwners are indexed by ZooNFTIDs, so .length() returns the number of ZooNFTIDs
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        (uint256 ZooNFTID, ) = _tokenOwners.at(index);
        return ZooNFTID;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 ZooNFTID) public virtual override {
        address owner = ownerOf(ZooNFTID);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, ZooNFTID);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 ZooNFTID) public view override returns (address) {
        require(_exists(ZooNFTID), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[ZooNFTID];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 ZooNFTID) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), ZooNFTID), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, ZooNFTID);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 ZooNFTID) public virtual override {
        safeTransferFrom(from, to, ZooNFTID, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 ZooNFTID, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), ZooNFTID), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, ZooNFTID, _data);
    }

    /**
     * @dev Safely transfers `ZooNFTID` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `ZooNFTID` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 ZooNFTID, bytes memory _data) internal virtual {
        _transfer(from, to, ZooNFTID);
        require(_checkOnERC721Received(from, to, ZooNFTID, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `ZooNFTID` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 ZooNFTID) internal view returns (bool) {
        return _tokenOwners.contains(ZooNFTID);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `ZooNFTID`.
     *
     * Requirements:
     *
     * - `ZooNFTID` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 ZooNFTID) internal view returns (bool) {
        require(_exists(ZooNFTID), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(ZooNFTID);
        return (spender == owner || getApproved(ZooNFTID) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `ZooNFTID` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `ZooNFTID` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 ZooNFTID, uint256 natureCode) internal virtual {
        _safeMint(to, ZooNFTID, natureCode,"");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 ZooNFTID, uint256 natureCode, bytes memory _data) internal virtual {
        _mintZooNFT(to, ZooNFTID, natureCode);
        require(_checkOnERC721Received(address(0), to, ZooNFTID, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _mintZooNFT(address to, uint256 ZooNFTID, uint256 natureCode) internal virtual;

    /**
     * @dev Destroys `ZooNFTID`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `ZooNFTID` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 ZooNFTID) internal virtual {
        address owner = ownerOf(ZooNFTID);

        _beforeTokenTransfer(owner, address(0), ZooNFTID);

        // Clear approvals
        _approve(address(0), ZooNFTID);

        _holderTokens[owner].remove(ZooNFTID);

        _tokenOwners.remove(ZooNFTID);

        emit Transfer(owner, address(0), ZooNFTID);
    }

    /**
     * @dev Transfers `ZooNFTID` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `ZooNFTID` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 ZooNFTID) internal virtual {
        require(ownerOf(ZooNFTID) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, ZooNFTID);

        // Clear approvals from the previous owner
        _approve(address(0), ZooNFTID);

        _holderTokens[from].remove(ZooNFTID);
        _holderTokens[to].add(ZooNFTID);

        _tokenOwners.set(ZooNFTID, to);

        emit Transfer(from, to, ZooNFTID);
    }


    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param ZooNFTID uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 ZooNFTID, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            ZooNFTID,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 ZooNFTID) internal {
        _tokenApprovals[ZooNFTID] = to;
        emit Approval(ownerOf(ZooNFTID), to, ZooNFTID);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `ZooNFTID` will be
     * transferred to `to`.
     * - When `from` is zero, `ZooNFTID` will be minted for `to`.
     * - When `to` is zero, ``from``'s `ZooNFTID` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 ZooNFTID) internal virtual { }
}
