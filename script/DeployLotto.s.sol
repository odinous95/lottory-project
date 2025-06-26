// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import {Script} from "forge-std/Script.sol";
import {LottoContract} from "../src/Lotto.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {InteractionsChainLink, FundSubscription, AddConsumer} from "./interactions.s.sol";

contract DeployLotto is Script {
    function run() public {
        deployContract();
    }

    function deployContract() public returns (LottoContract, HelperConfig) {
        HelperConfig config = new HelperConfig();
        HelperConfig.NetWorkConfig memory networkConfig = config
            .getConfigByChainId(block.chainid);
        if (networkConfig.subscriptionId == 0) {
            // If subscriptionId is 0, it means we are on a local network or the
            InteractionsChainLink interactionsChainLink = new InteractionsChainLink();
            (
                networkConfig.subscriptionId,
                networkConfig._vrfCoordinator
            ) = interactionsChainLink.createSubscription(
                networkConfig._vrfCoordinator
            );

            // Fund the subscription
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                networkConfig._vrfCoordinator,
                networkConfig.subscriptionId,
                networkConfig.link
            );
        }
        vm.startBroadcast();
        LottoContract lotto = new LottoContract(
            networkConfig.entryFee,
            networkConfig.interval,
            networkConfig._vrfCoordinator,
            networkConfig.keyhash,
            networkConfig.subscriptionId,
            networkConfig.callbackGasLimit
        );
        vm.stopBroadcast();
        // add the consumer to the subscription
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            address(lotto),
            networkConfig._vrfCoordinator,
            networkConfig.subscriptionId
        );

        return (lotto, config);
    }
}
