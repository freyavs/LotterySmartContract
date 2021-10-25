
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";

// he usado este tutorial: https://betterprogramming.pub/build-a-verifiably-random-lottery-smart-contract-on-ethereum-c1daacc1ca4e

contract Lottery {
    enum State { Open, Closed, Finished }
    State public state;
    int entryFee = 1;
    address[] entries;
    address randomNumberGenerator;
    
    //TODO: contractManager should be able to call finishLottery()
    //TODO: (pregunta) el gestora del contract deberia ser el Owner o no? -> if yes we should put Ownable in constructor
    address contractManager;

    event NewEntry(address player);
    event LotteryStateChanged(State newState);
    event NumberRequested(bytes32 requestId);
	event PlayerDrawn(bytes32 requestId, uint winningPlayerIndex);
    
    // modifier to be sure that the lottery is in the state it should be
    modifier isState(State _state) {
        require(state == _state, "Wrong state for this action");
        _;
    }
    
    //constructor
	constructor (uint _entryFee, address _contractManager, address _randomNumberGenerator) {
		require(_entryFee > 0, "Entry fee must be greater than 0");
		require(_randomNumberGenerator != address(0), "Random number generator must be valid address");
		require(_randomNumberGenerator.isContract(), "Random number generator must be smart contract");
		require(_contractManager != address(0), "Contract manager must be valid address");
		require(_contractManager.isContract(), "Contract manager must be smart contract");
		entryFee = _entryFee;
		randomNumberGenerator = _randomNumberGenerator;
		changeState(State.Open);
	}
    
    // players can only submit entry if the lottery is open
    // TODO: (pregunta) no estoy segura si "payabla" es necesario aqui
    function submitEntry() public payable isState(State.Open) {
        require(msg.value >= entryFee, "Minimum entry fee required");
        entries.add(msg.sender);
        emit NewEntry(msg.sender);
    }
    
    // gets called by contract manager / owner
    function finishLottery(uint256 _seed) public onlyOwner isState(State.Open){
        changeState(State.Closed);
        drawPlayer(_seed);
    }
    
    function drawPlayer(uint256 _seed) public {
		randomNumberRequestId = RandomNumberGenerator(randomNumberGenerator).request(_seed);
		emit NumberRequested(randomNumberRequestId);
	}
    
    // gets called in RandomNumberGenerator after calling drawPlayer()
    function playerDrawn(bytes32 _randomNumberRequestId, uint _randomNumber) public isState(State.Closed) {
		if (_randomNumberRequestId == randomNumberRequestId) {
			winningNumber = _randomNumber;
			uint playerIndex = _randomNumber % entries.length;
			emit PlayerDrawn(_randomNumberRequestId, playerIndex);
			pay(entries[playerIndex]);
			changeState(LotteryState.Finished);
		}
	}
	
	// give money to winning player
	function pay(address winner) private {
		uint balance = address(this).balance;
		payable(winner).transfer(balance);
	}

    
    function changeState(State newState) private {
		state = newState;
		emit LotteryStateChanged(state);
	}
    
}
