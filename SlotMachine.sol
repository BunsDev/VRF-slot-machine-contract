// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";


/*************************************************/
/* This contract will act as the treasury and */
/* manager of all the game clients */
/*************************************************/


// setup
// Owner will fund contract with ETH
// Owner will set up Chainlink VRF subscription and fund with LINK


// The contract will create clients that can speak to the main contract
// Each client will serve as a game client for the user
// I am doing this so there can be an unlimited number of game instances

// how to play
// 1. player will use startGame() to play
// 2. in startGame(), if player does not have a client, a client will be made
// 3. if a client is made, then playGame() is called


contract SlotMachineRouter is Ownable {

    //Chainlink variables to pass onto the client contract
    //which calls the VRFConsumerBase

    // The amount of LINK to send with the request
    uint256 public fee;
    // ID of public key against which randomness is generated
    bytes32 public keyHash;
    
    //vrfCoordinator address of VRFCoordinator contract
    address public vrfCoordinator;
    //linkToken address of LINK token contract
    address public linkToken;

   
   //constructor inherits a VRFConsumerBase and initiates the values for keyHash, 
   //fee 

    constructor(address _vrfCoordinator, address _linkToken,
    bytes32 vrfKeyHash, uint256 vrfFee)
    {
        keyHash = vrfKeyHash;
        fee = vrfFee;
        vrfCoordinator = _vrfCoordinator;
        linkToken = _linkToken;
    }

    
    //array of players
    address[] public players;

    //mapping of players to clients
    mapping(address => gameClient) public addressToClient;

    //We need a way to prove that a player has their own instance
    //lets try, creating a mapping that will associate a user with a boolean,
    //because i cant check if addressToClient returns null
    mapping(address => bool) public userHasClient;
    
    //start game function
    function startGame() public {
        if (userHasClient[msg.sender] == false )
        createClient(vrfCoordinator,linkToken,keyHash,fee);
        else
            //playGame();
        
    }
    
    //create client function
    function createClient(address _vrfCoordinator,address _linkToken, bytes32 _keyHash,_fee) internal {
        //creates new game client instance
        // need to add a check that assures it doesn't fail
        gameClient newGameClient = new gameClient(_vrfCoordinator,_linkToken,_keyHash,_fee);

        addressToClient[msg.sender] = newGameClient;

        //sets userHasClient to true
        userHasClient[msg.sender] == true;
    }

    // play game function
    // will use this function which calls functions in the user's client
    function play() public payable {

    }


    //function to send winnings to players (will modify later)
    // send the ether in the contract to the winner
    //(bool sent,) = winner.call{value: address(this).balance}("");
    // require(sent, "Failed to send Ether");

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

}


contract gameClient is VRFConsumerBase {

    // The amount of LINK to send with the request
    uint256 public fee;
    // ID of public key against which randomness is generated
    bytes32 public keyHash;

   constructor(address _vrfCoordinator, address _linkToken,
    bytes32 vrfKeyHash, uint256 vrfFee)
    VRFConsumerBase(_vrfCoordinator, _linkToken) {
        keyHash = vrfKeyHash;
        fee = vrfFee;
    }

     // the fees for entering the game
    uint256 immutable entryFee;

    //winnings to the player
    uint256 public winnings;

    address public player;


    //the function that is called by the router contract
    function playGame() private {
        require(msg.value == entryFee, "Value sent is not equal to entryFee");
        
    }

    /**
    * fulfillRandomness is called by VRFCoordinator when it receives a valid VRF proof.
    * This function is overrided to act upon the random number generated by Chainlink VRF.
    * @param requestId  this ID is unique for the request we sent to the VRF Coordinator
    * @param randomness this is a random unit256 generated and returned to us by the VRF Coordinator
   */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual override  {
 
        uint256 slot1 = randomness % 2;
        uint256 slot2 = randomness % 3;
        uint256 slot3 = randomness % 4;

    }

    function play() private returns (bytes32 requestId) {
        // LINK is an internal interface for Link token found within the VRFConsumerBase
        // Here we use the balanceOF method from that interface to make sure that our
        // contract has enough link so that we can request the VRFCoordinator for randomness
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        // Make a request to the VRF coordinator.
        // requestRandomness is a function within the VRFConsumerBase
        // it starts the process of randomness generation
        return requestRandomness(keyHash, fee);
    }



    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}



    }




