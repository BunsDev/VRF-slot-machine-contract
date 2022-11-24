// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/*
A truly random and fair slot machine 🎰
Made by Josh 
*/


// setup
// Owner will fund contract with ETH
// Owner will set up Chainlink VRF subscription and fund with LINK
// In constructor, owner will specify how much in dollars the game will cost to play


// how to play
// 1. player will use startGame() to play
// 2. 3 verifiably random numbers are produced and determine each slot's position
// 3. if the player wins, then winnings will be sent directly to their wallet or 
// we can make a credit system or whatever




contract SlotMachineRouter is VRFConsumerBaseV2  {

  //owner of contract
  address payable public owner;
  //entry fee to play
  uint entryFee;
    //denominated in USD
    mapping(address => uint) public userBalance;


  constructor(uint _entryFee, string memory _priceFeedAddress, uint64 subscriptionId, address _vrfCoordinator, bytes32 _keyHash) VRFConsumerBaseV2(vrfCoordinator) {
    entryFee = _entryFee;
    priceFeedAddress = _priceFeedAddress;
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_subscriptionId = subscriptionId;
    vrfCoordinator = _vrfCoordinator;
    keyHash = _keyHash;
    owner = payable(msg.sender);
  }

    //deposit MATIC
   function depositETH() public payable {
       (,int price,,,) = priceFeed.latestRoundData();
        uint chainlinkPrice = uint(price);
        uint chainlinkPriceTo4Digits = chainlinkPrice / 10 ** 4;
        uint amountWei = msg.value * chainlinkPriceTo4Digits;
        amountWei = amountWei / 10 ** 4;
        uint amountETH = amountWei / 1 ether;
        userBalance[msg.sender] = amountETH;
  }

  //deposit ERC20
  // 1 = DAI, 2 = USDC, 3 = USDT

  mapping(address => address) public userERC20Choice;

  function approveERC20(uint8 _choice) public returns (bool) {

    address DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
        

    if(_choice == 1){
      if (userERC20Choice[msg.sender] != DAI)
      {
        userERC20Choice[msg.sender] == DAI;
      }
    }
    else if(_choice == 2){
      if (userERC20Choice[msg.sender] != USDC){
      userERC20Choice[msg.sender] == USDC;
      }
    }
    else if(_choice ==3){
      if (userERC20Choice[msg.sender] != USDT){
      userERC20Choice[msg.sender] == USDT;
      }
    }

  return IERC20(userERC20Choice[msg.sender]).approve(address(this), entryFee * 1 ether );
   
  }

  function depositERC20(uint amount) public {

    IERC20(userERC20Choice[msg.sender]).transfer(address(this), amount);
    userBalance[msg.sender] = amount / 1 ether;
    
  }

/* ☆♬○♩●♪✧♩☆♬○♩●♪✧♩☆♬○♩●♪✧♩☆♬○♩●♪✧♩　Play Game (*triple H Theme*)　♩✧♪●♩○♬☆♩✧♪●♩○♬☆♩✧♪●♩○♬☆♩✧♪●♩○♬☆*/
    // play game function
    function playGame() public {

      //require entry fee is paid
      require(userBalance[msg.sender] == entryFee);
      userBalance[msg.sender] - entryFee;

      //reset mappings for the frontend
      delete addressToSlot1[msg.sender];
      delete addressToSlot2[msg.sender];
      delete addressToSlot3[msg.sender];
      delete addressToBalance[msg.sender];

      //request random numbers
      requestRandomWords();
      //fullFillRandomWords() is called by Chainlink which completes our game
        
    }
/* ☆♬○♩●♪✧♩☆♬○♩●♪✧♩☆♬○♩●♪✧♩☆♬○♩●♪✧♩　End of game　♩✧♪●♩○♬☆♩✧♪●♩○♬☆♩✧♪●♩○♬☆♩✧♪●♩○♬☆*/



// =!=!=!=!=!=!=!=!=!=! CHAINLINK PricefeedV3 St00f =!=!=!=!=!=!=!=!=!=!=!=!=!=!=!

  string priceFeedAddress;
  AggregatorV3Interface internal priceFeed;

  //this function calculates the cost in ether to play the game
  //the entry fee is denominated in dollars
  function getEntryFee() public view returns (uint) {
        //get ETH latest price
        (,int price,,,) = priceFeed.latestRoundData();
        //multiply price to prepare for division
        uint ETHprice = uint(price*10**18);
        //multiply dollar cost to prepare for division
        uint minDollars = entryFee * 10 ** 18;
        //calculate cost in ether
        uint fee = ((minDollars*10**18)/ETHprice) * 10 ** 8;

        return fee;
  }


//=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!

  
/* ｡･:*:･ﾟ★,｡･:*:･ﾟ☆　CHAINLINK VRF STUFF  ｡･:*:･ﾟ★,｡･:*:･ﾟ☆｡･:*:･ﾟ★,｡･:*:･ﾟ☆　　 ｡･:*:･ﾟ★,｡･:*:･ﾟ☆*/
    //coordinator object
    VRFCoordinatorV2Interface COORDINATOR;
        // Your subscription ID.
    uint64 s_subscriptionId;
        //vrfCoordinator address of VRFCoordinator contract
    address public vrfCoordinator;
    // ID of public key against which randomness is generated
    bytes32 public keyHash;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 100000;

        // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

      //number of random numbers  
    uint32 numWords = 3;

    //mapping to reference the address in fulfillrandomwords()
    mapping(uint256 => address) public s_requestIdToAddress;

    // Assumes the subscription is funded sufficiently.
  function requestRandomWords() internal {
    // Will revert if subscription is not set and funded.
    uint256 requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
    //mapping to pass address over to fulfillRandomWords
    s_requestIdToAddress[requestId] = msg.sender;
  }
/*♥*♡∞:｡.｡♥*♡∞:｡.｡♥*♡∞:｡.｡　FULFILL RANDOM WORDS　｡.｡:∞♡*♥｡.｡:∞♡*♥｡.｡:∞♡*♥       < ---------- */
  function fulfillRandomWords(
    uint256 requestId, 
    uint256[] memory randomWords
  ) internal override {

    address payable player = payable(s_requestIdToAddress[requestId]);

    //Get random words between 1 and 5
    uint256 slot1 = (randomWords[0] % 5) + 1;
    uint256 slot2 = (randomWords[1] % 5) + 1;
    uint256 slot3 = (randomWords[2] % 5) + 1;

    //sets the frontend mappings
    addressToSlot1[s_requestIdToAddress[requestId]] = slot1;
    addressToSlot2[s_requestIdToAddress[requestId]] = slot2;
    addressToSlot3[s_requestIdToAddress[requestId]] = slot3;

   //The Game
   if (slot1 == 1 && slot2 == 1 && slot3 == 1) {
    //Jackpot #1
    player.transfer(1 ether);
    addressToBalance[msg.sender] = 1 ether;

  }
  else if((slot1 == 1 && slot2 == 1) || (slot2 == 1 && slot3 == 2))
  {
    //if two 1's are next to eachother
    player.transfer(0.1 ether);
    addressToBalance[msg.sender] = 0.1 ether;
  }
  else if(slot1 == 2 && slot2 == 2 && slot3 == 2) {
    //Jackpot #2
    player.transfer(2 ether);
    addressToBalance[msg.sender] = 2 ether;
  }
  else if((slot1 == 2 && slot2 == 2) || (slot2 == 2 && slot3 == 2) ){
    //if two 2's are next to eachother
    player.transfer(0.2 ether);
    addressToBalance[msg.sender] = 0.2 ether;
  }
  else if(slot1 == 3 && slot2 == 3 && slot3 == 3) {
    //Jackpot #3
    player.transfer(3 ether);
    addressToBalance[msg.sender] = 3 ether;
  }
  else if((slot1 == 3 && slot2 == 3) || (slot2 == 3 && slot3 == 3) ){
    //if two 3's are next to eachother
    player.transfer(0.3 ether);
    addressToBalance[msg.sender] = 0.3 ether;
  }
  else if(slot1 == 4 && slot2 == 4 && slot3 == 4) {
    //Jackpot #4
    player.transfer(4 ether);
    addressToBalance[msg.sender] = 4 ether;
  }
  else if((slot1 == 4 && slot2 == 4) || (slot2 == 4 && slot3 == 4) ){
    //if two 4's are next to eachother
    player.transfer(0.4 ether);
    addressToBalance[msg.sender] = 0.4 ether;
  }
  else if(slot1 == 5 && slot2 == 5 && slot3 == 5) {
    //Jackpot #5
    player.transfer(5 ether);
    addressToBalance[msg.sender] = 5 ether;
  }
  else if((slot1 == 5 && slot2 == 5) || (slot2 == 5 && slot3 == 5) ){
    //if two 5's are next to eachother
    player.transfer(0.5 ether);
    addressToBalance[msg.sender] = 0.5 ether;
  }
  else{
       
  }

  }

/*♥*♡∞:｡.｡♥*♡∞:｡.｡♥*♡∞:｡.｡　END OF FULFILL RANDOM WORDS　｡.｡:∞♡*♥｡.｡:∞♡*♥｡.｡:∞♡*♥ */

/* ｡･:*:･ﾟ★,｡･:*:･ﾟ☆　END OF CHAINLINK VRF STUFF  ｡･:*:･ﾟ★,｡･:*:･ﾟ☆｡･:*:･ﾟ★,｡･:*:･ﾟ☆　　 ｡･:*:･ﾟ★,｡･:*:･ﾟ☆*/

    /* ============Some data to help the frontend =====================*/
    mapping (address => uint256) addressToSlot1;
    mapping (address => uint256) addressToSlot2;
    mapping (address => uint256) addressToSlot3;
    mapping (address => uint256) addressToBalance;

    function getSlot1(address _address) public view returns (uint256) {
      return addressToSlot1[_address];
    }

    function getSlot2(address _address) public view returns (uint256) {
      return addressToSlot2[_address];
    }

    function getSlot3(address _address) public view returns (uint256) {
      return addressToSlot3[_address];
    }

    function getBalance(address _address) public view returns (uint256) {
      return addressToBalance[_address];
    }

    //==================================================================

    //events 🎪
    event GameStarted(address indexed _from, uint _value);
    event Jackpot1(address indexed _from);
    event Two1s(address indexed _from);
    event Jackpot2(address indexed _from);
    event Two2s(address indexed _from);
    event Jackpot3(address indexed _from);
    event Two3s(address indexed _from);
    event Jackpot4(address indexed _from);
    event Two4s(address indexed _from);
    event Jackpot5(address indexed _from);
    event Two5s(address indexed _from);
    event Lose(address indexed _from);

    
    // Function to receive Ether. msg.data must be empty
   receive() external payable {}
    // Fallback function is called when msg.data is not empty
   fallback() external payable {}

}


interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
}
