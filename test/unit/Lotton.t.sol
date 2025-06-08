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
    }
}
