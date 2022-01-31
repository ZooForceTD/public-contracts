// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../sharedDependencies/extensions/SafeMath.sol";
import "../sharedDependencies/extensions/Ownable.sol";
import "../sharedDependencies/IZooForceNFTCore.sol";
import "../sharedDependencies/extensions/EnumerableSet.sol";
import "../sharedDependencies/extensions/EnumerableMapUintArray.sol";
import "../sharedDependencies/dependencies/IERC721Enumerable.sol";
import "../Accesorios/AccessoryCore.sol";



contract Presale is Ownable{
  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.UintSet;
  using EnumerableMapUintArray for EnumerableMapUintArray.UintToUintArrayMap;

  uint256  public START_TIMESTAMP = 0;
  uint256  public FULL_UNLOCK_TIMESTAMP = 0;
  uint256  public PRESALE_OPENING_TIMESTAMP = 3000000003;
  uint256  public END_TIMESTAMP = 3000000004;

  //@notice address allowed to balance NFTs prices 
  address public priceBalancer;

  address public  animalAddress;
  address public  accessoryAddress;
  address public  habitatAddress;

  mapping(address => bool) public whitelist;

  //@notice Times an address has spinned each roulette
  mapping(address => mapping (uint256 => uint256)) public quantityBought;
  //0 = baseAnimal(max5), 1 = accessory(max12), 2 = habitat(max1), 
  //3 = fullskin(max1) 

  //@notice Total number of times the first roulette (spinAnimalRoulette) has been spinned
  uint16 public animalsCount;
  //0 = lion, 1 = penguin, 2 = eagle,
  //3 = panther, 4 = chamaleon, 5 = bear
  //6 = monkey

  //@notice Number of times the second roulette (spinAccessoryRoulette) has been spinned (per selected specie)
  mapping(uint256 => uint16) public accessoriesMap; //specie => timesSpinned

  //@notice Number of times the third roulette (spinHabitatRoulette) has been spinned (per selected category)
  mapping(uint256 => uint16) public habitatsMap; //category => timesSpinned
    //0 = Beast: //331 max
    //      Lion
    //      Panther
    //      Bear
    //1 = Reptil: //114 max
    //      Chamaleon
    //2 = Aerial:  //114 max
    //      Eagle
    //3 = Acuatic:  //114 max
    //      Penguin
    //4 = Hervivorous:  //114 max
    //      Monkey

    
  //@notice Number of times the fourth roulette (spinFullskinRoulette) has been spinned (per selected rarity)
  mapping(uint256 => uint16) public fullskinMap; //rarity => timesSpinned
  //0 = rare; 1 = epic, 2 = legendary

  //@notice Cost in jagger of spinning each roullete (3, 4 and 5 corresponds to the fourth roulette)
  uint256[6] public pricesJager; 
  //0 = baseAnimal, 1 = accessory, 2 = habitat, 
  //3 = fullRare, 4 = fullEpic, 5 = fullLegendary

  //@notice Events with useful information for the presale page on the website
  event RoulleteSpinned(address indexed nftWinner, uint256 indexed eventCode, uint256 natureCode);
  event RoulleteSpinnedFullskin(address indexed nftWinner, uint256 indexed eventCode, uint256 natureCode);

  constructor(
    uint256[6] memory _pricesJager
  ) 
  public {
    pricesJager = _pricesJager;
    priceBalancer = msg.sender;
  }


  modifier ableToBuy() { 
    uint256 time = block.timestamp;
    require((whitelist[msg.sender] || time >= PRESALE_OPENING_TIMESTAMP), "Not Whitelisted nor Open"); //TESTEAR booleano implicito
    require(START_TIMESTAMP <= time && time < END_TIMESTAMP, "Presale Ended or hasn't started yet"); //TESTEAR booleano implicito
    _;
  }

  modifier ableToBuyPhase2(){ 
    uint256 time = block.timestamp;
    require((whitelist[msg.sender] || time >= PRESALE_OPENING_TIMESTAMP), "Not Whitelisted nor Open"); //TESTEAR booleano implicito
    require(FULL_UNLOCK_TIMESTAMP <= time && time <= END_TIMESTAMP, "Presale not in second phase yet"); //TESTEAR booleano implicito
    _;
  }

  //@dev Mints an animal and transfers it to buyer
  function spinAnimalRoulette() external payable ableToBuy{
    require(animalsCount<4000);
    animalsCount++;

    require(quantityBought[msg.sender][0]<5);
    quantityBought[msg.sender][0]++;

    uint256 value = msg.value;
    require(value >= pricesJager[0]);
    value -= pricesJager[0];

    //Calcular especie
    uint256 rouletteNumber = _getRandomUint(animalsCount);
    uint256 specie = rouletteNumber % 7;
    uint256 natureCode = rouletteNumber - rouletteNumber%1000 + 300 + specie;
    IZooForceNFTCore(animalAddress).createZooForceNFT( msg.sender, natureCode);
    msg.sender.transfer(value);
    emit RoulleteSpinned(msg.sender, specie, natureCode);
  }


  //@dev Mints an accessory with a defined specie in its natureCode and transfers it to buyer
  function spinAccessoryRoulette(uint8 _specie) external payable ableToBuyPhase2 {
    require(_specie<7);
    require(accessoriesMap[_specie]<1000);
    accessoriesMap[_specie]++;

    require(quantityBought[msg.sender][1]<12);
    quantityBought[msg.sender][1]++;

    uint256 value = msg.value;
    require(value >= pricesJager[1]);
    value -= pricesJager[1];
    //Calcular categoria(_specie), rareza y slot {(12(7),3(3),4(4)}
    uint256 rouletteNumber = _getRandomUint(accessoriesMap[_specie]);
    uint256 seccionDMil = rouletteNumber%10000;
    uint256 rareza;
    if(seccionDMil>8570){
      rareza = 200;
    } else if(seccionDMil>5710){
      rareza = 100;
    } else{
      rareza = 0;
    }
    uint256 slot = (seccionDMil%4) * 1000;
    uint256 natureCode = rouletteNumber - seccionDMil + slot + rareza + _specie ;
    IZooForceNFTCore(accessoryAddress).createZooForceNFT(msg.sender, natureCode);
    msg.sender.transfer(value);
    emit RoulleteSpinned(msg.sender, 10000 + slot + rareza * 10 + _specie, natureCode);
  }

  //@dev Mints an habitat with a defined category in its natureCode and transfers it to buyer
  function spinHabitatRoulette(uint8 _category) external payable ableToBuyPhase2{
    require(_category<5);
    if(_category == 0){
      require(habitatsMap[0]<331);
      habitatsMap[0]++;
    } else{
      require(habitatsMap[_category]<114);
      habitatsMap[_category]++;
    }

    require(quantityBought[msg.sender][2]<1);
    quantityBought[msg.sender][2]++;

    uint256 value = msg.value;
    require(value >= pricesJager[2]);
    value -= pricesJager[2];

    //Calcular categoria(_category) y rareza
    uint256 rouletteNumber = _getRandomUint(habitatsMap[_category]);
    uint256 seccionMil = rouletteNumber%1000;
    uint256 rareza;

    if(seccionMil>880){
      rareza = 200;
    } else if(seccionMil>610){
      rareza = 100;
    } else{
      rareza = 0;
    }
    uint256 natureCode = rouletteNumber - seccionMil + rareza + _category ;
    IZooForceNFTCore(habitatAddress).createZooForceNFT(msg.sender, natureCode);
    msg.sender.transfer(value);
    emit RoulleteSpinned(msg.sender, 20000 + rareza + _category, natureCode);
  }
  
  //@dev Mints an animal and four accessories with a defined rarity in its natureCode and transfers it to buyer
  function spinFullSkinRoulette(uint8 _rarity) external payable ableToBuyPhase2{
    require(_rarity<3, "Rarity non existen");
    if(_rarity == 0){
      require(fullskinMap[0]<400, "No rare left");
    } else if (_rarity == 1){
      require(fullskinMap[1]<200, "No epic left");
    } else {
      require(fullskinMap[2]<100, "No legendary left");
    }

    fullskinMap[_rarity]++;
    
    require(quantityBought[msg.sender][3]<1);
    quantityBought[msg.sender][3]++;

    uint256 value = msg.value;
    require(value >= pricesJager[3+_rarity]);
    value -= pricesJager[3+_rarity];

    //Calcular categoria y rareza(_rarity)
    uint256 rouletteNumber = _getRandomUint(fullskinMap[_rarity]);

    uint256 species = rouletteNumber%7;

    uint256 repetitiveData = _rarity*100+species;
    uint256 natureCode = rouletteNumber - rouletteNumber%1000 + repetitiveData;

    uint256[4] memory accCode;
    uint256 quality = uint256(keccak256(abi.encodePacked(block.timestamp, natureCode)));
    quality = quality-quality%10000;
    // quality = quality - quality%10000+ i*1000 + _rarity*100+species;
    for(uint i = 0; i<4;i++){
      accCode[i] = quality-quality%10000 + i*1000 + repetitiveData;
    }
    AccessoryCore(accessoryAddress).createZooForceNFTBatch(msg.sender, accCode);
    
    IZooForceNFTCore(animalAddress).createZooForceNFT(msg.sender, natureCode);
    msg.sender.transfer(value);
    emit RoulleteSpinnedFullskin(msg.sender, 40000 + _rarity * 100 + species, natureCode);
  }

  //@dev Creates a totally random uint256
  function _getRandomUint(uint256 _nonce) internal view returns(uint256){ // Nonce is always nft remaining quantitiy
    uint256 blockHashUint = uint256(blockhash(block.number));
    uint256 randomNumber =
        uint256(keccak256(abi.encodePacked(
          blockHashUint, 
          block.timestamp, 
          _nonce)));
    return randomNumber;
  }

  //@dev Updates prices for NFTs in case BNB fluctuates too much while the presale is held
  function updatePrices(uint256[6] calldata _adjustedPrices) external{
    require(msg.sender == priceBalancer, "Not the Price Balancer");
    pricesJager = _adjustedPrices;
  }

  //@dev Whitdraws BNB from contract
  function withdrawBNB() external onlyOwner{
    payable(owner()).transfer(address(this).balance);
  }

  //@dev Ends presale early
  function endPresale() external onlyOwner{
    END_TIMESTAMP = 0;
  }

  //@dev Open presale early
  function openPresale() external onlyOwner{
    PRESALE_OPENING_TIMESTAMP = 0;
  }

  //@dev Set NFTs cores addresses
  function setNFTAddresses(address _animalAddress, address _accessoryAddress, address _habitatAddress) external onlyOwner{
    animalAddress = _animalAddress;
    accessoryAddress = _accessoryAddress;
    habitatAddress = _habitatAddress;
  }

  //@dev Add addresses to whitelist
  function addWhitelistedAddresses(address[] calldata _whitelistedAddresses) external onlyOwner{
    for(uint256 i =0; i<_whitelistedAddresses.length;i++){
      whitelist[_whitelistedAddresses[i]] = true;
    }
  }

  //@dev Returns the number of times a roulette has been spinned
  function getBougthNFTs(address _buyer) view external returns(uint8[4] memory){
    uint8[4] memory timesSpinned;
    for(uint i = 0; i<4; i++){
      timesSpinned[i] = uint8(quantityBought[_buyer][i]);
    }
    return timesSpinned;
  }

  //@dev Returns total of NFTs bougth and the roulettes prices
  function getAnimalsAndPrices() external view returns(uint16[16] memory, uint256[6] memory){
    uint16[16] memory nftsQuantities; 

    //ACCESSORIOS
    nftsQuantities[0]  = accessoriesMap[0];
    nftsQuantities[1]  = accessoriesMap[1];
    nftsQuantities[2]  = accessoriesMap[2];
    nftsQuantities[3]  = accessoriesMap[3];
    nftsQuantities[4]  = accessoriesMap[4];
    nftsQuantities[5]  = accessoriesMap[5];
    nftsQuantities[6]  = accessoriesMap[6];
    
    //HABITATS
    nftsQuantities[7]  = habitatsMap[0];
    nftsQuantities[8]  = habitatsMap[1];
    nftsQuantities[9]  = habitatsMap[2];
    nftsQuantities[10]  = habitatsMap[3];
    nftsQuantities[11] = habitatsMap[4];

    //FULLSKIN
    nftsQuantities[12] = fullskinMap[0];
    nftsQuantities[13] = fullskinMap[1];
    nftsQuantities[14] = fullskinMap[2];

    //ANIMAL
    nftsQuantities[15] = animalsCount;
    
    return (nftsQuantities, pricesJager);
  }

  function getNFTAddresses() view external returns(address[3] memory){
    return [animalAddress, accessoryAddress, habitatAddress];
  }

  function isOpen() view external returns(bool){
    return (PRESALE_OPENING_TIMESTAMP <= block.timestamp);
  }

  function isStarted() view external returns(bool){
    return (START_TIMESTAMP <= block.timestamp);
  }

  function isEnd() view external returns(bool){
    return (END_TIMESTAMP <= block.timestamp);
  }

  function setPriceBalancer(address _priceBalancer) external onlyOwner{
    priceBalancer = _priceBalancer;
  }
}