// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

library MainnetDeployConfig {
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    // 200 gwei
    bytes32 constant KEY_HASH = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
    uint32 constant CALLBACK_GAS_LIMIT = 2_500_000;
    // TODO: set this once you configure it on Chainlink UI
    uint64 constant SUBSCRIPTION_ID = 0;
    uint16 constant REQUEST_CONFIRMATIONS = 3;
    address constant VRF_COORDINATOR = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    address constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
}
