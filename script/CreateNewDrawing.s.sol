// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "@forge-std/console.sol";
import {Script} from "@forge-std/Script.sol";
import {Jackpot} from "../src/Jackpot.sol";
import {LatestDeployedContract} from "./configs/LatestDeployedContract.sol";

contract CreateNewDrawing is Script {
    Jackpot jackpot;

    function run() external {
        uint256 chainId = vm.envUint("CHAIN_TO_DEPLOY_ON");
        string memory ipfsHash = vm.envString("IPFS_HASH");
        vm.startBroadcast();
        if (chainId != 1) {
            revert("Unsupported chain");
        }
        jackpot = Jackpot(LatestDeployedContract.DEPLOYED_CONTRACT);
        jackpot.createNewDrawing(ipfsHash);
        uint256 count = jackpot.getDrawingCount();
        uint256 newDrawingId = count - 1;
        console.log("New drawing id: %d", newDrawingId);
        vm.stopBroadcast();
    }
}
