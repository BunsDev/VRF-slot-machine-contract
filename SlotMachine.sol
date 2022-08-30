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
    //address to owner mapping
    mapping(address => gameClient) public addressToClient;
    
    function startGame() public {
        
        createClient(msg.sender);
    }
    
    //create client function
    function createClient(address player) internal {
        //creates new pet NFT
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




