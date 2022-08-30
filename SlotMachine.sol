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

// I think i will try adding 2 extra helper contracts to give 3 truly random numbers
// how to play
// 1. player will use startGame() to play
// 2. in startGame(), if player does not have a client, a client will be made
// 3. if a client is made, continue


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

    uint256 public s_requestId;

    constructor(uint64 subscriptionId, address _vrfCoordinator, bytes32 _keyHash) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_subscriptionId = subscriptionId;
    vrfCoordinator = _vrfCoordinator;
    keyHash = _keyHash;
  }

  
    // Assumes the subscription is funded sufficiently.
  function requestRandomWords() internal {
    // Will revert if subscription is not set and funded.
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  }

     //gets random numbers
  function fulfillRandomWords(
    uint256, 
    uint256[] memory randomWords
  ) internal override {
   addressToClient[msg.sender].s_randomWords = (randomWords[0] % [5]);
  }

    //gameClient struct
    struct gameClient {
    uint256[] s_randomWords;
    //slots
    uint256 slot1;
    uint256 slot2;
    uint256 slot3;
    uint256 winnings;
    bool gameActive;
    }

    // play game function
    // will use this function which calls functions in the user's client
    function playGame() public payable {
        require(msg.value == entryFee);
        requestRandomWords();
        fulfillRandomWords(s_requestId, addressToClient[msg.sender].s_randomWords);


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
