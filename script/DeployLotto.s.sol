// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import {Script} from "forge-std/Script.sol";
import {LottoContract} from "../src/Lotto.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {InteractionsChainLink} from "./interactions.s.sol";

contract DeployLotto is Script {
    function run() external {}

    function deployContract() external returns (LottoContract, HelperConfig) {
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

        return (lotto, config);
    }
}
