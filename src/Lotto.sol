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
    uint256 private s_lastTimestamp;
    uint256 private immutable i_interval;

    /* -=-=-=-=-=      Events   */
    event Lotto_Entered(address indexed participant, uint256 amount);

    /* -=-=-=-=-=    Constructor   */
    constructor(uint256 entryFee, uint256 interval) {
        interval = i_interval; // Set the interval for the lottery in seconds
        s_lastTimestamp = block.timestamp; // Initialize the last timestamp
        i_entryFee = entryFee;
    }

    /* -=-=-=-=-=      Contract Functions   */
    /// @notice Allows a participant to enter the lottery by sending the required entry fee.
    function enterLottery() external payable {
        if (msg.value < i_entryFee) {
            revert Lotto_NotEnoughEthSent();
        }
        s_participants.push(payable(msg.sender));
        emit Lotto_Entered(msg.sender, msg.value);
    }

    /// @notice Picks a winner from the participants if the lottery is ready.
    function pickWinner() external view returns (address) {
        if (block.timestamp - s_lastTimestamp < i_interval) {
            revert("Lottery is not ready to pick a winner yet.");
        }
        require(s_participants.length > 0, "No participants in the lottery.");
        return msg.sender;
    }

    /* -=-=-=-=-=  
    Getter Functionsa 
    **/

    function getEntryFee() public view returns (uint256) {
        return i_entryFee;
    }
}
