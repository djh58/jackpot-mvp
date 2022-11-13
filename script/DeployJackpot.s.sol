// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "@forge-std/console.sol";
import {Script} from "@forge-std/Script.sol";
import {Jackpot} from "../src/Jackpot.sol";

// TODO
contract DeployJackpot is Script {

    function run() external {
        vm.startBroadcast();
        vm.stopBroadcast();
    }
}
