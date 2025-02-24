// SPDX-License-Identifiter: MIT

pragma solidity ^0.8.19;

import {Test} from "lib/forge-std/src/Test.sol";
import {SimpleLottery} from "src/Raffle.sol";

contract SimpleLotteryTest is Test {
    SimpleLottery public lottery;
    address public player1;
    address public player2;
    address public nonManager;
    address managerPlayer;

    event PlayerEntered(address indexed player, uint256 amount);
    event WinnerPicked(address indexed winner, uint256 amount, uint256 lotteryId);

    function setUp() public {
        lottery = new SimpleLottery();

        player1 = address(0x1);
        player2 = address(0x2);
        nonManager = address(0x3);
        managerPlayer = address(0x4);

        lottery.setManager(managerPlayer);
    }

    function testOnlyManagerCanPickWinner() public {
        vm.prank(nonManager);
        vm.expectRevert(SimpleLottery.Raffle__OnlyManagerCanStartRaffle.selector);
        lottery.pickWinner();
    }

    function testEnterLotteryWithSufficientFunds() public {
        vm.deal(player1, 1 ether);
        vm.prank(player1);
        lottery.enterLottery{value: 0.01 ether}();

        address[] memory players = lottery.getPlayers();
        assertEq(players.length, 1);
        assertEq(players[0], player1);
    }

    function testEnterLotteryWithInsufficientFunds() public {
        vm.deal(player1, 1 ether);
        vm.prank(player1);
        vm.expectRevert(SimpleLottery.Raffle__MoreFundsNeededToEnterRaffle.selector);

        lottery.enterLottery{value: 0.005 ether}();
    }

    function testPickWinner() public {
        vm.deal(player1, 1 ether);
        vm.deal(player2, 1 ether);

        vm.prank(player1);
        lottery.enterLottery{value: 0.01 ether}();

        vm.prank(player2);
        lottery.enterLottery{value: 0.01 ether}();

        vm.prank(lottery.manager());
        lottery.pickWinner();

        address[] memory winners = lottery.getWinners();
        assertEq(winners.length, 1);
    }

    function testWithdrawFunds() public {
        vm.deal(player1, 1 ether);
        vm.prank(player1);
        lottery.enterLottery{value: 0.1 ether}();

        uint256 initialBalance = address(lottery).balance;
        assertEq(initialBalance, 0.1 ether);

        vm.prank(managerPlayer);
        lottery.withdrawFunds();

        uint256 finalBalance = address(lottery).balance;
        assertEq(finalBalance, 0);
        assertEq(initialBalance, 0.1 ether);
    }

    function testWithdrawFundsWithNoBalance() public {
        vm.expectRevert(SimpleLottery.Raffle__WithdrawalFailed.selector);
        vm.prank(managerPlayer);
        lottery.withdrawFunds();
    }

    function testEnterLotteryViaFallback() public {
        vm.deal(player1, 1 ether);
        vm.prank(player1);
        vm.expectEmit(true, true, false, true);
        emit PlayerEntered(player1, 0.01 ether);

        (bool success,) = address(lottery).call{value: 0.01 ether}("");
        assert(success);
    }
}
