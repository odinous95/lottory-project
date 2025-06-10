// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {LottoContract} from "src/Lotto.sol";
import {DeployLotto} from "script/DeployLotto.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract LottoTest is Test {
    LottoContract public lotto;
    HelperConfig public config;
    // Constants for testing
    address public PARTICIPANT_1 = makeAddr("participant1");
    uint256 public constant PARTICIPANT_1_BALANCE = 10 ether;
    uint256 entryFee;
    uint256 interval;
    address _vrfCoordinator;
    bytes32 keyhash;
    uint256 subscriptionId;
    uint32 callbackGasLimit;

    function setUp() public {
        // Deploy the LottoContract using the DeployLotto script
        DeployLotto deployer = new DeployLotto();
        (lotto, config) = deployer.deployContract();
        HelperConfig.NetWorkConfig memory networkConfig = config
            .getConfigByChainId(block.chainid);
        entryFee = networkConfig.entryFee;
        interval = networkConfig.interval;
        _vrfCoordinator = networkConfig._vrfCoordinator;
        keyhash = networkConfig.keyhash;
        subscriptionId = networkConfig.subscriptionId;
        callbackGasLimit = networkConfig.callbackGasLimit;
        // Set up initial balances for participants
        vm.deal(PARTICIPANT_1, PARTICIPANT_1_BALANCE);
    }

    // Test to check if the contract is deployed correctly and initialized  with open state
    function testLottoStartWithOpenState() public view {
        assert(lotto.getLottoState() == LottoContract.LottoState.OPEN);
    }

    // test entry lotto
    function testLottorWillRevertWithoutEnoughFee() public {
        // Arrange
        vm.prank(PARTICIPANT_1);
        //Act
        vm.expectRevert(LottoContract.Lotto_NotEnoughEthSent.selector);
        // Assert
        lotto.enterLottery();
    }

    // Lotto contract records new participants
    function testLottoRecordsNewParticipant() public {
        // Arrange
        vm.prank(PARTICIPANT_1);
        // Act
        lotto.enterLottery{value: entryFee}();
        // Assert
        assertEq(lotto.getParticipants(0), PARTICIPANT_1);
    }

    // events testing
    // Test that the Lotto_Entered event is emitted when a participant enters the lottery
    function testEnteringLottoEventEmit() public {
        // Arrange
        vm.prank(PARTICIPANT_1);
        // Act
        vm.expectEmit(true, false, false, false, address(lotto));
        emit LottoContract.Lotto_Entered(PARTICIPANT_1, entryFee);
        lotto.enterLottery{value: entryFee}();
    }
}
