// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
import "./AnimalMinteableERC721.sol";
import "../sharedDependencies/IZooForceNFTCore.sol";
import "../sharedDependencies/dependencies/IERC20.sol";
import "../sharedDependencies/extensions/AccessControl.sol";
import "../sharedDependencies/extensions/Ownable.sol";

contract AnimalCore is AnimalMinteableERC721, AccessControl, Ownable, IZooForceNFTCore {

    uint256 public nextTokenId = 1;

    address public zooAddress;
    address public presaleAddress;
    address public accessoryAddress;

    constructor(address _presale)
        ERC721Metadata("Animal","ZFANIMAL")
        public{
        presaleAddress = _presale;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setRoleAdmin(PAUSED_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(CREATOR_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(PAUSED_ROLE, _msgSender());
        _setupRole(CREATOR_ROLE, presaleAddress);
    }

    modifier onlyZoo() {
        require(_msgSender() == zooAddress, "Not called from Zoo");
        _;
    }

    modifier onlyCreator() {
        require(hasRole(CREATOR_ROLE,_msgSender()), "Not called from a Creator");
        _;
    }

    function createZooForceNFT(address _owner, uint256 _natureCode) override external onlyCreator {
        _mintZooNFT(_owner, nextTokenId, _natureCode);

        nextTokenId++;
    }

    /// @notice Returns all the relevant information about a specific Animal.
    /// @param _id The ID of the Animal of interest.
    function getAnimal(uint256 _id)
        public
        view
        returns (uint256 birthMoment, uint256 natureCode){
        Animal storage animal = Animals[_id - 1];

        birthMoment = uint256(animal.birthMoment);
        natureCode = animal.natureCode;
    }

    function setZooAddress(address _newZooAddress) public onlyOwner {
        grantRole(CREATOR_ROLE,_newZooAddress);
        revokeRole(CREATOR_ROLE, zooAddress);
        zooAddress = _newZooAddress;
    }

    //PAUSE
    function pause() public whenNotPaused {
        require(hasRole(PAUSED_ROLE, _msgSender()), "Must have pause role");
        _pause();
    }

    function unpause() public whenPaused {
        require(hasRole(PAUSED_ROLE, _msgSender()), "Must have pause role");
        _unpause();
    }
}
