//SPDX-license-Identifier: MIT
pragma solidity ^0.8.0;
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {HelperConfig, ConstantVars} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract InteractionsChainLink is Script {
    function run() public {
        createChainlinkSubscriptionId();
    }

    function createChainlinkSubscriptionId() public returns (uint256, address) {
        HelperConfig config = new HelperConfig();
        HelperConfig.NetWorkConfig memory networkConfig = config
            .getConfigByChainId(block.chainid);
        address vrfCoordinator = networkConfig._vrfCoordinator;
        (uint256 subId, ) = createSubscription(vrfCoordinator);
        return (subId, vrfCoordinator);
    }

    // Create a Chainlink VRF subscription
    function createSubscription(
        address vrfCoordinator
    ) public returns (uint256, address) {
        console.log(
            "Creating subscription on VRF Coordinator:",
            vrfCoordinator
        );
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        return (subId, vrfCoordinator);
    }
}

// fund the Chainlink VRF subscription
contract FundSubscription is Script, ConstantVars {
    uint256 public constant FUND_AMOUNT = 3 ether; // Amount to fund the subscription

    function run() public {
        HelperConfig config = new HelperConfig();
        HelperConfig.NetWorkConfig memory networkConfig = config
            .getConfigByChainId(block.chainid);
        address vrfCoordinator = networkConfig._vrfCoordinator;
        uint256 subId = networkConfig.subscriptionId;
        address linkToken = networkConfig.link;
        fundSubscription(vrfCoordinator, subId, linkToken);
    }

    // Fund the Chainlink VRF subscription
    function fundSubscription(
        address vrfCoordinator,
        uint256 subId,
        address linkToken
    ) public {
        console.log(
            "Funding subscription ID %s on VRF Coordinator: %s with LINK token: %s",
            subId,
            vrfCoordinator,
            linkToken
        );
        if (block.chainid == LOCALHOST_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
                subId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            console.log(
                "Funding subscription is not supported on this network. Please fund it manually."
            );
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subId)
            );
            vm.stopBroadcast();
        }
    }
}

contract AddConsumer is Script {
    function addCosumerUsingConfig(address mostRecentLotto) public {
        HelperConfig config = new HelperConfig();
        HelperConfig.NetWorkConfig memory networkConfig = config
            .getConfigByChainId(block.chainid);
        address vrfCoordinator = networkConfig._vrfCoordinator;
        uint256 subId = networkConfig.subscriptionId;
        addConsumer(mostRecentLotto, vrfCoordinator, subId);
    }

    function addConsumer(
        address contractToAdd,
        address vrfCoordinator,
        uint256 subId
    ) public {
        console.log(
            "Adding consumer %s to subscription ID  on VRF Coordinator: %s",
            contractToAdd,
            subId,
            vrfCoordinator
        );
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(
            subId,
            contractToAdd
        );
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentLotto = DevOpsTools.get_most_recent_deployment(
            "LottoContract",
            block.chainid
        );
        console.log("Most recent Lotto contract address:", mostRecentLotto);
        addCosumerUsingConfig(mostRecentLotto);
    }
}
