// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

// testing libraries
import "@forge-std/Test.sol";

// contract dependencies
import {Jackpot} from "../Jackpot.sol";
import {MockVRF} from "../mock/MockVRF.sol";
import {MainnetDeployConfig} from "../../script/configs/MainnetDeployConfig.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";

contract JackpotTest is Test {
    using SafeERC20 for IERC20;

    Jackpot public jackpot;
    MockVRF public vrf;
    uint256 mainnetFork;

    function setUp() public {
        mainnetFork = vm.createSelectFork(vm.rpcUrl("mainnet"));
        vrf = new MockVRF();
        jackpot = new Jackpot(
            MainnetDeployConfig.USDC,
            MainnetDeployConfig.KEY_HASH,
            MainnetDeployConfig.CALLBACK_GAS_LIMIT,
            MainnetDeployConfig.SUBSCRIPTION_ID,
            MainnetDeployConfig.REQUEST_CONFIRMATIONS,
            // need to mock VRF, all the other configs don't matter for testing locally / off a fork
            address(vrf)
        );
    }

    /**
     * TODO:
     * -set keyhash
     * -set subId
     * -set callback gas limit
     * -set request confirmations
     * -setup raffle
     * -conduct raffle (mocked out via raw external fulfill call)
     */

    function testSetKeyHash() public {
        // this contract is the deployer so it is the admin and is able to call the setters
        vm.selectFork(mainnetFork);
        bytes32 newHash = 0x9af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
        jackpot.setKeyHash(newHash);
        assertEq(jackpot.keyHash(), newHash);
    }

    function testSetSubscriptionId() public {
        // this contract is the deployer so it is the admin and is able to call the setters
        vm.selectFork(mainnetFork);
        uint64 newSubId = 6487;
        jackpot.setSubscriptionId(newSubId);
        assertEq(jackpot.subscriptionId(), newSubId);
    }

    function testSetCallbackGasLimit() public {
        // this contract is the deployer so it is the admin and is able to call the setters
        vm.selectFork(mainnetFork);
        uint32 newCallbackGasLimit = 2_300_000;
        jackpot.setCallbackGasLimit(newCallbackGasLimit);
        assertEq(jackpot.callbackGasLimit(), newCallbackGasLimit);
    }

    function testSetRequestConfirmations() public {
        // this contract is the deployer so it is the admin and is able to call the setters
        vm.selectFork(mainnetFork);
        uint16 newRequestConfirmations = 5;
        jackpot.setRequestConfirmations(newRequestConfirmations);
        assertEq(jackpot.requestConfirmations(), newRequestConfirmations);
    }

    function testSetupRaffle() public {
        _doRaffleSetup();
        vm.selectFork(mainnetFork);
        address[] memory users = jackpot.getRaffleUsers(1);
        assertEq(users[0], 0xBEeFbeefbEefbeEFbeEfbEEfBEeFbeEfBeEfBeef);
        assertEq(jackpot.getRafflePrizeAmounts(1)[0], 1000e6);
        assertEq(jackpot.getRaffleUpperLimitXP(1), 150);
        assertEq(jackpot.getRaffleUserXp(1, 0xbABEBABEBabeBAbEBaBeBabeBABEBabEBAbeBAbe), 150);
    }

    function testRaffle() public {
        address winner = 0xbABEBABEBabeBAbEBaBeBabeBABEBabEBAbeBAbe;
        uint256 initialBal = IERC20(jackpot.USDC()).balanceOf(winner);
        _doRaffleSetup();
        vm.selectFork(mainnetFork);
        vm.startPrank(address(vrf));
        uint256[] memory randomWordList = new uint256[](1);
        randomWordList[0] = 104;
        jackpot.rawFulfillRandomWords(1, randomWordList);
        vm.stopPrank();
        uint256 finalBal = IERC20(jackpot.USDC()).balanceOf(winner);
        uint256 delta = finalBal - initialBal;
        assertEq(delta, 1000e6);
    }

    function _doRaffleSetup() internal {
        // this contract is the deployer so it is the admin and is able to call the setters
        vm.selectFork(mainnetFork);
        uint256 raffleId = 1;
        address[] memory participants = new address[](2);
        participants[0] = 0xBEeFbeefbEefbeEFbeEfbEEfBEeFbeEfBeEfBeef;
        participants[1] = 0xbABEBABEBabeBAbEBaBeBabeBABEBabEBAbeBAbe;

        uint256[] memory xpAmounts = new uint256[](2);
        // first user has 50 xp
        xpAmounts[0] = 50;
        // second user has 100 xp
        xpAmounts[1] = 150;

        uint256[] memory usdcAmounts = new uint256[](1);
        // usdc amount is 1000
        usdcAmounts[0] = 1000e6;

        deal(jackpot.USDC(), address(jackpot), 1000e6);

        jackpot.setupRaffle(participants, xpAmounts, usdcAmounts);
    }
}
