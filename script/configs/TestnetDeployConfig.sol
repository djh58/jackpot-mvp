// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

library TestnetDeployConfig {
    // 150 gwei
    bytes32 constant KEY_HASH = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
    uint32 constant CALLBACK_GAS_LIMIT = 2_500_000;
    uint64 constant SUBSCRIPTION_ID = 6487;
    uint16 constant REQUEST_CONFIRMATIONS = 3;
    address constant VRF_COORDINATOR = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;
    address constant LINK = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
}
