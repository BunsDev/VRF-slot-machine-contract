// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


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


contract SlotMachineRouter {
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
        createClient(msg.sender);
        else
            //playGame();
        
    }
    
    //create client function
    function createClient(address player) internal {
        //creates new game client instance
        gameClient newGameClient = new gameClient(player);
        addressToClient[msg.sender] = newGameClient;
    }
}


contract gameClient {

    address public player;
    
    constructor(address _player) {
    player = _player;
    }


    }




