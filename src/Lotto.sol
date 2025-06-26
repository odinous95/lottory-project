// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/// @title Lotto Contract
/// @author Odin
/// @notice This contract implements a lottery system where participants can enter for a chance to win a prize.
/// @dev Provides functions to enter the lottery, pick a winner, and manage the lottery state.

contract LottoContract is VRFConsumerBaseV2Plus {
    /* -=-=-=-=-= Errors   */
    error Lotto_NotEnoughEthSent();
    error Lotto_NotOpen();
    error Lotto_UpkeepNeeded(
        uint256 contractBalance,
        uint256 participantsCount,
        LottoState lottoState
    );

    /* -=-=-=-=-= types-=-=-=-=-= -=-=-=-=-= -=-=-=-=-= -=-=-=-=-= */
    enum LottoState {
        OPEN,
        CLOSED
    }

    /* -=-=-=-=-= State Variables-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=   */
    // immutable variables
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint256 public immutable i_entryFee;
    uint256 private immutable i_interval;
    uint32 private immutable i_callbackGasLimit; // Gas limit for the callback function
    // storage variables
    address payable[] private s_participants; // Array to hold participants
    address private s_last_winnder; // Address of the last winner
    uint256 private s_lastTimestamp;
    LottoState private s_lottoState;
    bool public enableNativePayment = false; // Flag to enable native payment
    // contstants for VRF request
    uint16 private constant REQUEST_CONFIRMATIONS = 3; // Number of confirmations before fulfilling
    uint32 private constant NUM_WORDS = 1; // Number of random words to request

    /* -=-=-=-=-= Events   */
    event Lotto_Entered(address indexed participant, uint256 amount);

    /* -=-=-=-=-= Constructor  -=-=-=-=-= -=-=-=-=-= -=-=-=-=-= -=-=-=-=-= -=-=-=-=-=*/
    constructor(
        uint256 entryFee,
        uint256 interval,
        address _vrfCoordinator,
        bytes32 keyhash,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        i_interval = interval; // Set the interval for the lottery in seconds
        i_entryFee = entryFee;
        i_keyHash = keyhash; // Set the key hash for VRF
        i_subscriptionId = subscriptionId; // Set the subscription ID for VRF
        i_callbackGasLimit = callbackGasLimit; // Set the gas limit for the callback function
        s_lottoState = LottoState.OPEN; // Initialize the lottery state to OPEN
        s_lastTimestamp = block.timestamp; // Initialize the last timestamp
    }

    /* -=-=-=-=-=Contract Functions -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= */
    /// @notice Allows a participant to enter the lottery by sending the required entry fee.
    /**
     * @dev Allows a participant to enter the lottery by sending the required entry fee.
     * Reverts if the sent value is less than the entry fee or if the lottery is not open.
     */

    function enterLottery() external payable {
        if (msg.value < i_entryFee) {
            revert Lotto_NotEnoughEthSent();
        }
        if (s_lottoState != LottoState.OPEN) {
            revert Lotto_NotOpen();
        }
        s_participants.push(payable(msg.sender));
        emit Lotto_Entered(msg.sender, msg.value);
    }

    /// @notice Checks if the lottery is ready for upkeep trigger.
    /**
     *@dev Checks if the lottery is ready for upkeep trigger.
     * 1.if the lottery is open,
     * 2.enough time has passed since the last timestamp,
     * 3.there are participants in the lottery.
     * 4.the contract has enough balance to pay the winner.
     * 5.implicity we have link balance to pay for the upkeep
     * @return upkeepNeeded indicates if upkeep is needed
     */

    // -==-=--=-=-=-= Upkeep Functions -==-=--=-=-=-=-==-=--=-=-=-=-==-=--=-=-=-=

    function checkUpKeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool Lottery_isOpen = s_lottoState == LottoState.OPEN;
        bool timePassed = (block.timestamp - s_lastTimestamp) >= i_interval;
        bool hasParticipants = s_participants.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded =
            Lottery_isOpen &&
            timePassed &&
            hasParticipants &&
            hasBalance;
        return (upkeepNeeded, "0x");
    }

    /// @notice Performs upkeep to pick a winner from the participants.
    /**
     * @dev Performs upkeep to pick a winner from the participants.
     * Reverts if upkeep is not needed.
     * Calls the VRF Coordinator to get a random number for selecting the winner.
     */
    function performUpKeep(bytes memory /* checkData */) external {
        (bool upkeepNeeded, ) = checkUpKeep("");
        if (!upkeepNeeded) {
            revert Lotto_UpkeepNeeded(
                address(this).balance,
                s_participants.length,
                s_lottoState
            );
        }
        s_lottoState = LottoState.CLOSED; // Set the lottery state to CLOSED
        // make a request to the VRF Coordinator to get a random number
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        nativePayment: enableNativePayment
                    })
                )
            });
        s_vrfCoordinator.requestRandomWords(request);
    }

    //--=-=-=-=-=-=-=-- VRF Callback Function
    /// @notice Callback function to fulfill random words from the VRF Coordinator.
    /**
     * @dev Callback function to fulfill random words from the VRF Coordinator.
     * Selects a winner from the participants based on the random number received.
     * Resets the lottery state and participants for the next round.
     * Transfers the contract balance to the winner.
     */
    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] calldata randomWords
    ) internal override {
        uint256 winnerIndex = randomWords[0] % s_participants.length;
        address payable last_winner = s_participants[winnerIndex];
        s_last_winnder = last_winner; // Store the winner address
        s_lottoState = LottoState.OPEN; // Reset the lottery state to OPEN
        s_participants = new address payable[](0); // Reset the participants array
        s_lastTimestamp = block.timestamp; // Update the last timestamp
        (bool success, ) = last_winner.call{value: address(this).balance}(""); // Transfer the balance of the contract to the winner
        if (!success) {
            revert("Transfer to winner failed.");
        }
    }

    /* -=-=-=-=-=-=-=-=-- Getter Functions -=-=-=-=-=-=-=-=---=-=-=-=-=-=-=-=--   */
    /// @notice getter functions
    /// @dev Provides various getter functions to retrieve contract state variables.

    function getEntryFee() external view returns (uint256) {
        return i_entryFee;
    }

    function getLottoState() external view returns (LottoState) {
        return s_lottoState;
    }

    function getParticipants(uint256 index) external view returns (address) {
        return s_participants[index];
    }
}
