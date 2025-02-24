// SPDX-License-Identifier: MIT


pragma solidity ^0.8.19;



contract SimpleLottery {


    error Raffle__MoreFundsNeededToEnterRaffle();
    error Raffle__NoPlayersEnteredRaffle();
    error Raffle__PrizeTransferToWinnerFailed();
    error Raffle__OnlyManagerCanStartRaffle();
    error Raffle__WithdrawalFailed();


    address public manager;
    address[] private s_players;
    address[] public winners;
    uint256 public lotteryId;

    event PlayerEntered(address indexed player, uint256 amount);
    event WinnerPicked(address indexed winner, uint256 amount, uint256 lotteryId);



    constructor () {
        manager = msg.sender;
        lotteryId = 1;
    }


    function enterLottery() public payable {

        if (msg.value < 0.01 ether) {
            revert Raffle__MoreFundsNeededToEnterRaffle();
        }
        
        s_players.push(msg.sender);

        emit PlayerEntered(msg.sender, msg.value);

    }


    receive() external payable {
        if(msg.value < 0.01 ether) {
            revert Raffle__MoreFundsNeededToEnterRaffle();
        }

        enterLottery();
    }


    function pickWinner () public onlyManager {
        if (s_players.length == 0) {
            revert Raffle__NoPlayersEnteredRaffle();
        }

        uint256 winnerIndex = random() % s_players.length;
        address winner = s_players[winnerIndex];
        winners.push(winner);

        uint256 prizeAmount = address(this).balance;

        s_players = new address[](0);
        lotteryId++;
        
        (bool success, ) = payable(winner).call{value: prizeAmount}("");
        if (!success) {
            revert Raffle__PrizeTransferToWinnerFailed();
        }

        emit WinnerPicked(winner, prizeAmount, lotteryId);
    }


    function withdrawFunds() public onlyManager {
        uint256 balance = address(this).balance;

        if(balance == 0) {
            revert Raffle__WithdrawalFailed();
        }

        (bool success, ) = payable(manager).call{value: balance}("");

        if(!success) {
            revert Raffle__WithdrawalFailed();
        }
    }



    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }


    function getPlayers() public view returns(address[] memory) {
        return s_players;
    }


    function random() private view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, s_players.length)));
    }



    modifier onlyManager {
        if (msg.sender != manager) {
            revert Raffle__OnlyManagerCanStartRaffle();
        }
        _;
    }

}