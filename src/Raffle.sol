// SPDX-License-Identifier: MIT


pragma solidity ^0.8.19;



contract SimpleLottery {

    address public manager;
    address[] public players;
    address[] public winners;

    constructor () {
        manager = msg.sender;
    }


    function enterLottery() public payable {

        require(msg.value >= 0.01 ether, "Minimum 0.01 ETH required to enter");
        players.push(msg.sender);

    }


    receive() external payable {
        enterLottery();
    }


    function pickWinner () public {
        require(msg.sender == manager, "Only manager can pick a winner");
        require(players.length > 0, "No players in the lottery");

        uint256 winnerIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, players.length))) % players.length;
        address winner = players[winnerIndex];
        winners.push(winner);

        payable(winner).transfer(address(this).balance);
        players = new address[](0);
    }

}