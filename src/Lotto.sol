// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

/// @title Lotto Contract
/// @author Odin
/// @notice This contract implements a lottery system where participants can enter for a chance to win a prize.
/// @dev Provides functions to enter the lottery, pick a winner, and manage the lottery state.

contract LottoContract {
    uint256 public immutable i_entryFee;

    constructor(uint256 entryFee) {
        i_entryFee = entryFee;
    }

    function enterLottery() public payable {}

    function pickWinner() public returns (address) {}

    /*
    Getter Functionsa 
    **/

    function getEntryFee() public view returns (uint256) {
        return i_entryFee;
    }
}
