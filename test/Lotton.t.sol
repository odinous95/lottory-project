// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;
import {Test} from "forge-std/Test.sol";
import {LottoContract} from "../src/Lotto.sol";

contract LottoTest is Test {
    LottoContract public lotto;

    function setUp() public {
        lotto = new LottoContract(0.01 ether, 86400);
    }

    function testEntryFeeCheck() public view {
        uint256 entryFee = lotto.getEntryFee();
        assertEq(entryFee, 0.01 ether, "Entry fee should be 0.01 ether");
    }

    function testEnterLotteryForPlayer() public {
        vm.deal(address(this), 1 ether); // Give this contract some ether
        lotto.enterLottery{value: 0.01 ether}();
        // Additional checks can be added here to verify state changes
    }

    // function testPickWinner() public {
    //     // This function would require more setup to test properly
    //     // For now, we can just call it to ensure it doesn't revert
    //     address winner = lotto.pickWinner();
    //     assertNotEq(winner, address(0), "Winner should not be zero address");
    // }
}
