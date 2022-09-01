// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/*
Made by Josh
                              .-------.
                              |Jackpot|
                  ____________|_______|____________
                 |  __    __    ___  _____   __    |  
                 | / _\  / /   /___\/__   \ / _\   | 
                 | \ \  / /   //  //  / /\ \\ \  25|  
                 | _\ \/ /___/ \_//  / /  \/_\ \ []| 
                 | \__/\____/\___/   \/     \__/ []|
                 |===_______===_______===_______===|
                 ||*|\_     |*| _____ |*|\_     |*||
                 ||*|| \ _  |*||     ||*|| \ _  |*||
                 ||*| \_(_) |*||*BAR*||*| \_(_) |*||
                 ||*| (_)   |*||_____||*| (_)   |*|| __
                 ||*|_______|*|_______|*|_______|*||(__)
                 |===_______===_______===_______===| ||
                 ||*| _____ |*|\_     |*|  ___  |*|| ||
                 ||*||     ||*|| \ _  |*| |_  | |*|| ||
                 ||*||*BAR*||*| \_(_) |*|  / /  |*|| ||
                 ||*||_____||*| (_)   |*| /_/   |*|| ||
                 ||*|_______|*|_______|*|_______|*||_//
                 |===_______===_______===_______===|_/
                 ||*|  ___  |*|   |   |*| _____ |*||
                 ||*| |_  | |*|  / \  |*||     ||*||
                 ||*|  / /  |*| /_ _\ |*||*BAR*||*||              
                 ||*| /_/   |*|   O   |*||_____||*||        
                 ||*|_______|*|_______|*|_______|*||
                 |lc=___________________________===|
                 |  /___________________________\  |
                 |   |                         |   |
                _|    \_______________________/    |_
               (_____________________________________)



*/


// setup
// Owner will fund contract with ETH
// Owner will set up Chainlink VRF subscription and fund with LINK


// how to play
// 1. player will use startGame() to play
// 2. 3 verifiably random numbers are produced and determine each slot's position
// 3. if the player wins, then winnings will be sent directly to their wallet or 
// we can make a credit system or whatever


contract SlotMachineRouter is VRFConsumerBaseV2, Ownable{

    //entry fee to play
    uint256 entryFee = 0.01 ether;

    //We need a way to prove that a player has their own instance
    mapping(address => bool) public userHasPlayedOnce;


/* ☆♬○♩●♪✧♩☆♬○♩●♪✧♩☆♬○♩●♪✧♩☆♬○♩●♪✧♩　Play Game (*triple H Theme*)　♩✧♪●♩○♬☆♩✧♪●♩○♬☆♩✧♪●♩○♬☆♩✧♪●♩○♬☆*/
    // play game function
    function playGame() public payable {

        //require entry fee is paid
        require(msg.value == entryFee);

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

    constructor(uint64 subscriptionId, address _vrfCoordinator, bytes32 _keyHash) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_subscriptionId = subscriptionId;
    vrfCoordinator = _vrfCoordinator;
    keyHash = _keyHash;
  }
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
  else if((slot1 == 1 && slot2 == 1) || (slot2 == 1 && slot3 == 2) )
  {
    //if two 1's are next to eachother
    player.transfer(0.5 ether);
    addressToBalance[msg.sender] = 0.5 ether;
  }
  else if(slot1 == 2 && slot2 == 2 && slot3 == 2) {
    //Jackpot #2
    player.transfer(1 ether);
    addressToBalance[msg.sender] = 1 ether;
  }
  else if((slot1 == 2 && slot2 == 2) || (slot2 == 2 && slot3 == 2) ){
    //if two 2's are next to eachother
    player.transfer(0.5 ether);
    addressToBalance[msg.sender] = 0.5 ether;
  }
  else if(slot1 == 3 && slot2 == 3 && slot3 == 3) {
    //Jackpot #3
    player.transfer(1 ether);
    addressToBalance[msg.sender] = 1 ether;
  }
  else if((slot1 == 3 && slot2 == 3) || (slot2 == 3 && slot3 == 3) ){
    //if two 3's are next to eachother
    player.transfer(0.5 ether);
    addressToBalance[msg.sender] = 0.5 ether;
  }
  else if(slot1 == 4 && slot2 == 4 && slot3 == 4) {
    //Jackpot #4
    player.transfer(1 ether);
    addressToBalance[msg.sender] = 1 ether;
  }
  else if((slot1 == 4 && slot2 == 4) || (slot2 == 4 && slot3 == 4) ){
    //if two 4's are next to eachother
    player.transfer(0.5 ether);
    addressToBalance[msg.sender] = 0.5 ether;
  }
  else if(slot1 == 5 && slot2 == 5 && slot3 == 5) {
    //Jackpot #5
    player.transfer(1 ether);
    addressToBalance[msg.sender] = 1 ether;
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

    /* Some data to help the frontend */
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
    
    // Function to receive Ether. msg.data must be empty
   receive() external payable {}
    // Fallback function is called when msg.data is not empty
   fallback() external payable {}

}
