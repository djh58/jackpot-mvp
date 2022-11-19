// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "@forge-std/console.sol";
import {Script} from "@forge-std/Script.sol";
import {Jackpot} from "../src/Jackpot.sol";
import {MainnetDeployConfig} from "./configs/MainnetDeployConfig.sol";
import {TestnetDeployConfig} from "./configs/TestnetDeployConfig.sol";
// TODO

contract DeployJackpot is Script {
    Jackpot jackpot;

    function run() external {
        uint256 chainId = vm.envUint("CHAIN_TO_DEPLOY_ON");
        vm.startBroadcast();
        if (chainId == 1) {
            jackpot = new Jackpot(
                MainnetDeployConfig.USDC,
                MainnetDeployConfig.KEY_HASH,
                MainnetDeployConfig.CALLBACK_GAS_LIMIT,
                MainnetDeployConfig.SUBSCRIPTION_ID,
                MainnetDeployConfig.REQUEST_CONFIRMATIONS,
                MainnetDeployConfig.VRF_COORDINATOR
            );
        } else if (chainId == 5) {
            jackpot = new Jackpot(
                TestnetDeployConfig.USDC,
                TestnetDeployConfig.KEY_HASH,
                TestnetDeployConfig.CALLBACK_GAS_LIMIT,
                TestnetDeployConfig.SUBSCRIPTION_ID,
                TestnetDeployConfig.REQUEST_CONFIRMATIONS,
                TestnetDeployConfig.VRF_COORDINATOR
            );
        } else {
            revert("Unsupported chain");
        }
        vm.stopBroadcast();
    }
}
