// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./RandomNumberGenerator.sol";

// he usado este tutorial: https://betterprogramming.pub/build-a-verifiably-random-lottery-smart-contract-on-ethereum-c1daacc1ca4e

contract Lottery {
    enum State { Open, Closed }
    State public state;
    uint public entryFee = 1;
    bytes32 randomNumberRequestId;
    address[] entries;
    address randomNumberGenerator;
    address contractManager;
    uint public winningPlayerIndex;

    event NewEntry(address player);
    event LotteryStateChanged(State newState);
    event NumberRequested(bytes32 requestId);
	event PlayerDrawn(bytes32 requestId, uint winningPlayerIndex);
    
    // modifier to be sure that the lottery is in the state it should be
    modifier isState(State _state) {
        require(state == _state, "Wrong state for this action");
        _;
    }
    
    // constructor
	constructor (uint _entryFee, address _contractManager, address _randomNumberGenerator) {
		require(_entryFee > 0, "Entry fee must be greater than 0");
		require(_randomNumberGenerator != address(0), "Random number generator must be valid address");
		require(isContract(_randomNumberGenerator), "Random number generator must be smart contract");
		require(_contractManager != address(0), "Contract manager must be valid address");
		require(isContract(_contractManager), "Contract manager must be smart contract");
		entryFee = _entryFee;
		randomNumberGenerator = _randomNumberGenerator;
		changeState(State.Open);
	}
    
    // players can only submit entry if the lottery is open
    function submitEntry() public payable isState(State.Open) {
        require(msg.value >= entryFee, "Minimum entry fee required");
        entries.push(msg.sender);
        emit NewEntry(msg.sender);
    }
    
    // gets called by contract manager
    function finishLottery(uint256 _seed) public isState(State.Open){
        require(msg.sender == contractManager, "Only contract manager can finish the lottery.");
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
			winningPlayerIndex = _randomNumber % entries.length;
			emit PlayerDrawn(_randomNumberRequestId, winningPlayerIndex);
			pay(entries[winningPlayerIndex]);
			reset();
		}
	}
	
	// give money to winning player
	function pay(address winner) private {
		uint balance = address(this).balance;
		payable(winner).transfer(balance);
	}
	
	// reset the lottery  
    function reset() private {
        delete entries;
        changeState(State.Open);
        
	}
    
    function changeState(State newState) private {
		state = newState;
		emit LotteryStateChanged(state);
	}
	
	// warning from https://ethereum.stackexchange.com/questions/15641/how-does-a-contract-find-out-if-another-address-is-a-contract
	// --> EXTCODESIZE returns 0 if it is called from the constructor of a contract. So if you are using this in a security sensitive setting, you would have to consider if this is a problem.
	function isContract(address _addr) private returns (bool iscontract){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
    
}
