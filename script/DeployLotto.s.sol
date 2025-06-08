// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import {Script} from "forge-std/Script.sol";
import {LottoContract} from "../src/Lotto.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployLotto is Script {
    function run() external {}

    function deployContract() external returns (LottoContract, HelperConfig) {
        HelperConfig config = new HelperConfig();
        HelperConfig.NetWorkConfig memory networkConfig = config
            .getConfigByChainId(block.chainid);

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
