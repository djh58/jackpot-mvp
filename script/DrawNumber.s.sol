// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "@forge-std/console.sol";
import {Script} from "@forge-std/Script.sol";
import {Jackpot} from "../src/Jackpot.sol";
import {LatestDeployedContract} from "./configs/LatestDeployedContract.sol";

contract DrawNumber is Script {
    Jackpot jackpot;

    function run() external {
        uint256 chainId = vm.envUint("CHAIN_TO_DEPLOY_ON");
        uint256 drawingId = vm.envUint("CONTRACT_DRAWING_ID");
        vm.startBroadcast();
        if (chainId != 1) {
            revert("Unsupported chain");
        }
        jackpot = Jackpot(LatestDeployedContract.DEPLOYED_CONTRACT);
        jackpot.drawNumber(drawingId);
        vm.stopBroadcast();
    }
}
