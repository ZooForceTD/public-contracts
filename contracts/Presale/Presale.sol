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

  uint256  public START_TIMESTAMP = 0; //1642802400
  uint256  public FULL_UNLOCK_TIMESTAMP = 0; //
  uint256  public PRESALE_OPENING_TIMESTAMP = 3000000003;
  uint256  public END_TIMESTAMP = 3000000004;

  
  address priceBalancer;

  address animalAddress;
  address accessoryAddress;
  address habitatAddress;

  mapping(address => bool) public whitelist;

  mapping(address => mapping (uint256 => uint256)) public quantityBought;
  //0 = baseAnimal(max5), 1 = accessory(max12), 2 = habitat(max1), 
  //3 = fullskin(max1) 

  uint16 public animalsCount; //Elegible por nada
  //0 = leon, 1 = pinguino, 2 = aguila,
  //3 = pantera, 4 = camaleon, 5 = oso
  //6 = mono

  mapping(uint256 => uint16) public accessoriesMap; //especie => cantidadSobrante || 7000/7 = 1000
  //Elegible por especie

  mapping(uint256 => uint16) public habitatsMap; //categoria => cantidadSobrante || 789 = 474, 217, 98 
    //Elegible por categoria
    //0 = Bestia: //331
    //      León
    //      Pantera
    //      Oso
    //1 = Reptil: //114
    //      Camaleón
    //2 = Aéreo:  //114
    //      Aguila
    //3 = Agua:  //114
    //      Pinguino
    //4 = Herbívoro:  //114
    //      Mono

    

  mapping(uint256 => uint16) public fullskinMap; //rareza => cantidadSobrante || 700 = 400, 200, 100
  //Elegible por rareza
    
  uint256[6] public pricesJager; 
  //0 = baseAnimal, 1 = accessory, 2 = habitat, 
  //3 = fullRare, 4 = fullEpic, 5 = fullLegendary
  
  event RoulleteSpinned(address indexed nftWinner, uint256 indexed eventCode, uint256 natureCode);
  event RoulleteSpinnedFullskin(address indexed nftWinner, uint256 indexed eventCode, uint256 natureCode);
  //000-005 Animal(Especie)
  //1000-1999 Accesorios(Rareza)
  //2000-2999 Habitat(Rareza)
  //3000-3999 Fullskin(Especie)

  constructor(
    uint256[6] memory _pricesJager
    ) 
  public {
    pricesJager = _pricesJager;
    // whitelist[msg.sender] = true;
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
    require(FULL_UNLOCK_TIMESTAMP <= time && time <= END_TIMESTAMP, "Presale Ended or hasn't started yet"); //TESTEAR booleano implicito
    _;
  }

  function spinAnimalRoulette() external payable ableToBuy{
    require(animalsCount<4000, "Animal count muy gande");
    animalsCount++;
    require(quantityBought[msg.sender][0]<5, "Para un toque man");
    quantityBought[msg.sender][0]++;
    require(msg.value >= pricesJager[0], "POBRE");
    //Calcular especie
    uint256 rouletteNumber = _getRandomUint(animalsCount);
    uint256 specie = rouletteNumber % 7;
    uint256 natureCode = rouletteNumber - rouletteNumber%1000 + 300 + specie;
    IZooForceNFTCore(animalAddress).createZooForceNFT( msg.sender, natureCode);
    emit RoulleteSpinned(msg.sender, specie, natureCode);
  }



  function spinAccessoryRoulette(uint8 _specie) external payable ableToBuyPhase2 {
    require(_specie<7, "Specie non existen!");
    require(accessoriesMap[_specie]<1000, "Not enough accessories of this specie left!");
    accessoriesMap[_specie]++;

    require(quantityBought[msg.sender][1]<12);
    quantityBought[msg.sender][1]++;

    require(msg.value >= pricesJager[1], "Poor!");

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

    emit RoulleteSpinned(msg.sender, 10000 + slot + rareza * 10 + _specie, natureCode);
  }

  function spinHabitatRoulette(uint8 _category) external payable ableToBuyPhase2{
    require(_category<5);
    if(_category == 0){
      require(habitatsMap[0]<331, "Habitats of beast no left!");
      habitatsMap[0]++;
    } else{
      require(habitatsMap[_category]<114, "Habitats of specie no left!");
      habitatsMap[_category]++;
    }

    require(quantityBought[msg.sender][2]<1);
    quantityBought[msg.sender][2]++;

    require(msg.value >= pricesJager[2], "Poor!");

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
    emit RoulleteSpinned(msg.sender, 20000 + rareza + _category, natureCode);
  }
  
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

    require(msg.value >= pricesJager[3+_rarity], "Poor!");

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
    emit RoulleteSpinnedFullskin(msg.sender, 40000 + _rarity * 100 + species, natureCode);
  }

  
  function _getRandomUint(uint256 _nonce) internal returns(uint256){ // Nonce is always nft remaining quantitiy
    uint256 blockHashUint = uint256(blockhash(block.number));
    uint256 randomNumber =
        uint256(keccak256(abi.encodePacked(
          blockHashUint, 
          block.timestamp, 
          _nonce)));
    return randomNumber;
  }

  function updatePrices(uint256[6] calldata _adjustedPrices) external{
    require(msg.sender == priceBalancer, "Not the Price Balancer");
    pricesJager = _adjustedPrices;
  }

  function withdrawBNB() external onlyOwner{
    payable(owner()).transfer(address(this).balance);
  }

  function endPresale() external onlyOwner{
    END_TIMESTAMP = 0;
  }

  function openPresale() external onlyOwner{
    PRESALE_OPENING_TIMESTAMP = 0;
  }

  function setNFTAddresses(address _animalAddress, address _accessoryAddress, address _habitatAddress) external onlyOwner{
    animalAddress = _animalAddress;
    accessoryAddress = _accessoryAddress;
    habitatAddress = _habitatAddress;
  }

  function addWhitelistedAddresses(address[] calldata _whitelistedAddresses) external onlyOwner{
    for(uint256 i =0; i<_whitelistedAddresses.length;i++){
      whitelist[_whitelistedAddresses[i]] = true;
    }
  }

  //@dev Actually returns the number of times a roulette has been spinned
  function getBougthNFTs(address _buyer) view external returns(uint8[4] memory){
    uint8[4] memory timesSpinned;
    for(uint i = 0; i<4; i++){
      timesSpinned[i] = uint8(quantityBought[_buyer][i]);
    }
    return timesSpinned;
  }


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

  // receive() external payable{
  // }

}