// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

abstract contract ConstantVars {
    uint256 internal constant ENTRY_FEE = 0.01 ether;
    uint256 internal constant INTERVAL = 30; // seconds
    bytes32 internal constant KEYHASH =
        0x6c3699283bda56ad74f6b855546325b68d482e984d9f8a1c5c5f8e2e2e2e2e2e;
    uint256 internal constant SUBSCRIPTION_ID =
        88826966090256723369999427220919917385522212386661270330706476491180325452552;
    uint32 internal constant CALLBACK_GAS_LIMIT = 100000;
    uint256 public constant ETH_SEPIOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCALHOST_CHAIN_ID = 31337;
    address public constant LINK_TOKEN_ADDRESS =
        0x779877A7B0D9E8603169DdbD7836e478b4624789; // Sepolia LINK token address
    // VRFCoordinatorV2_5Mock public vrfCoordinator mock;
    uint96 public constant MOCK_BASE_FEE = 0.25 ether;
    uint96 public constant MOCK_GAS_PRICE_LINK = 0.0001 ether;
    int256 public constant MOCK_WEI_PER_UNIT_LINK = 0.01 ether;
}

contract HelperConfig is ConstantVars, Script {
    error helperConfig__ChainIdNotSupported(uint256 chainId);
    struct NetWorkConfig {
        uint256 entryFee;
        uint256 interval;
        address _vrfCoordinator;
        bytes32 keyhash;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        address link; // Link token address, not used in this example
    }
    NetWorkConfig public activeNetworkConfig;
    mapping(uint256 chainId => NetWorkConfig) public networkConfigs;

    // Constructor to initialize the network configurations
    constructor() {
        networkConfigs[ETH_SEPIOLIA_CHAIN_ID] = getSepoliaConfig();
    }

    // Get the configuration for a specific chain ID
    function getConfigByChainId(
        uint256 chainId
    ) public returns (NetWorkConfig memory) {
        if (networkConfigs[chainId]._vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCALHOST_CHAIN_ID) {
            return getAnvilConfig();
        } else {
            revert helperConfig__ChainIdNotSupported(chainId);
        }
    }

    // Get the configuration for different networks
    function getAnvilConfig() public returns (NetWorkConfig memory) {
        if (activeNetworkConfig._vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        }
        // deply mock VRFCoordinatorV2Mock
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock mock_vrfCoordinator = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE_LINK,
            MOCK_WEI_PER_UNIT_LINK
        );
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();
        activeNetworkConfig = NetWorkConfig({
            entryFee: ENTRY_FEE,
            interval: INTERVAL,
            _vrfCoordinator: address(mock_vrfCoordinator),
            keyhash: KEYHASH,
            subscriptionId: SUBSCRIPTION_ID,
            callbackGasLimit: CALLBACK_GAS_LIMIT,
            link: address(linkToken) // Mock VRFCoordinator has LINK token address
        });
        return activeNetworkConfig;
    }

    // Get the configuration for Sepolia network
    function getSepoliaConfig() public pure returns (NetWorkConfig memory) {
        return
            NetWorkConfig({
                entryFee: ENTRY_FEE,
                interval: INTERVAL,
                _vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                keyhash: KEYHASH,
                subscriptionId: SUBSCRIPTION_ID,
                callbackGasLimit: CALLBACK_GAS_LIMIT,
                link: LINK_TOKEN_ADDRESS // Sepolia LINK token address
            });
    }
}
