// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";


/*************************************************/
/* This contract will act as the treasury and */
/* manager of all the game clients */
/*************************************************/


// setup
// Owner will fund contract with ETH
// Owner will set up Chainlink VRF subscription and fund with LINK
// There is a structure/ i can possibly use mappings instead, for each player to save certain data.


// how to play
// 1. player will use startGame() to play
// 2. in startGame(), if player does not have a client, a client will be made
// 3. if a client is made, then the game will start
// 4. 3 verifiably random numbers are produced and determine each slot's position
// 5. if the player wins, then winnings will be sent directly to their wallet or we can make a credit system or whatever


contract SlotMachineRouter is VRFConsumerBaseV2{
    address owner = msg.sender;

    //array of players
    address[] public players;

    uint256 entryFee;
    //mapping of players to client struct
    mapping(address => gameClient) public addressToClient;

    //We need a way to prove that a player has their own instance
    //lets try, creating a mapping that will associate a user with a boolean,
    //because i cant check if addressToClient returns null
    mapping(address => bool) public userHasClient;

    //Chainlink variables to pass onto the client structs
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

      //number of random words  
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
    s_requestIdToAddress[requestId] = msg.sender;
  }


    //gameClient struct
    //need to store slots for front end
    struct gameClient {
    //slots
    uint256 slot1;
    uint256 slot2;
    uint256 slot3;
    uint256 winnings;
    bool gameActive;
    
    }

  function fulfillRandomWords(
    uint256 requestId, 
    uint256[] memory randomWords
  ) internal override {

    //Get random words

    uint256 slot1 = randomWords[0];
    uint256 slot2 = randomWords[1];
    uint256 slot3 = randomWords[2];
  


   //The Game
   if (slot1 == 1 && slot2 == 1 && slot3 == 1) {
       
   } 
   else if((slot1 == 1 && slot2 == 1) || (slot2 == 1 && slot3 == 1) ) {
       //if two 1's are next to eachother
   }
   else if(slot1 == 2 && slot2 == 2 && slot3 == 2) {
       //Jackpot 2
   }
   else if((slot1 == 2 && slot2 == 2) || (slot2 == 2 && slot3 == 2) ){
       //if two 2's are next to eachother
   }
   else if(slot1 == 3 && slot2 == 3 && slot3 == 3) {
       //Jackpot 3
   }
   else if((slot1 == 3 && slot2 == 3) || (slot2 == 3 && slot3 == 3) ){
       //if two 3's are next to eachother
   }
   else if(slot1 == 4 && slot2 == 4 && slot3 == 4) {
     //Jackpot 4
   }
   else if((slot1 == 4 && slot2 == 4) || (slot2 == 4 && slot3 == 4) ){
       //if two 4's are next to eachother
   }
   else if(slot1 == 5 && slot2 == 5 && slot3 == 5) {
    //Jackpot 5
   }
   else if((slot1 == 5 && slot2 == 5) || (slot2 == 5 && slot3 == 5) ){
       //if two 5's are next to eachother
   }


  }

    // play game function
    // will use this function which calls functions in the user's client
    function playGame() public payable {
        require(msg.value == entryFee);
        requestRandomWords();
        //fulfill random words()
        

    }

    //function to send winnings to players (will fix later)
    // send the ether in the contract to the winner
    //(bool sent,) = winner.call{value: address(this).balance}("");
    // require(sent, "Failed to send Ether");

    // Function to receive Ether. msg.data must be empty
   // receive() external payable {}
    // Fallback function is called when msg.data is not empty
   // fallback() external payable {}

}
