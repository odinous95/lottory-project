// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

/// @title Lotto Contract
/// @author Odin
/// @notice This contract implements a lottery system where participants can enter for a chance to win a prize.
/// @dev Provides functions to enter the lottery, pick a winner, and manage the lottery state.

contract LottoContract {
    /* -=-=-=-=-=    Errors   */
    error Lotto_NotEnoughEthSent();

    /* -=-=-=-=-=     State Variables   */
    uint256 public immutable i_entryFee;
    address payable[] private s_participants; // Array to hold participants

    /* -=-=-=-=-=      Events   */
    event Lotto_Entered(address indexed participant, uint256 amount);

    /* -=-=-=-=-=    Constructor   */
    constructor(uint256 entryFee) {
        i_entryFee = entryFee;
    }

    /* -=-=-=-=-=      Contract Functions   */
    function enterLottery() public payable {
        if (msg.value < i_entryFee) {
            revert Lotto_NotEnoughEthSent();
        }
        s_participants.push(payable(msg.sender));
        emit Lotto_Entered(msg.sender, msg.value);
    }

    function pickWinner() public returns (address) {}

    /* -=-=-=-=-=  
    Getter Functionsa 
    **/

    function getEntryFee() public view returns (uint256) {
        return i_entryFee;
    }
}
