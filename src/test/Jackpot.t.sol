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
        string memory MAINNET_RPC_URL = vm.envString("RPC_MAINNET_URL");
        mainnetFork = vm.createSelectFork(MAINNET_RPC_URL);
        vrf = new MockVRF();
        jackpot = new Jackpot(
            MainnetDeployConfig.KEY_HASH,
            MainnetDeployConfig.CALLBACK_GAS_LIMIT,
            MainnetDeployConfig.SUBSCRIPTION_ID,
            MainnetDeployConfig.REQUEST_CONFIRMATIONS,
            // need to mock VRF, all the other configs don't matter for testing locally / off a fork
            address(vrf)
        );
    }

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

    /// write unit tests for createNewDrawing, updateDrawingIpfsHash, and drawNumber

    function testCreateNewDrawing() public {
        // this contract is the deployer so it is the admin and is able to call the sette
        vm.selectFork(mainnetFork);
        string memory ipfsHash = "foo";
        jackpot.createNewDrawing(ipfsHash);
        uint256 drawing_num = jackpot.getDrawingCount() - 1;
        string memory hash_saved = jackpot.getIpfsHashFromDrawingId(drawing_num);
        assertEq(hash_saved, ipfsHash);
    }

    function testUpdateDrawingIpfsHash() public {
        // this contract is the deployer so it is the admin and is able to call the sette
        vm.selectFork(mainnetFork);

        string memory ipfsHash = "foo";
        jackpot.createNewDrawing(ipfsHash);
        uint256 drawing_num = jackpot.getDrawingCount() - 1;

        string memory newIpfsHash = "fee";
        jackpot.updateDrawingIpfsHash(newIpfsHash, drawing_num);

        string memory hash_saved = jackpot.getIpfsHashFromDrawingId(drawing_num);
        assertEq(hash_saved, newIpfsHash);
    }

    function testdrawNumber() public {
        // this contract is the deployer so it is the admin and is able to call the sette
        vm.selectFork(mainnetFork);

        string memory ipfsHash = "foo";
        jackpot.createNewDrawing(ipfsHash);
        uint256 drawing_num = jackpot.getDrawingCount() - 1;
        jackpot.drawNumber(drawing_num);
        vm.startPrank(address(vrf));
        uint256 randomNumExpected = 104;
        uint256 reqIdExpected = 1;
        uint256[] memory randomWordList = new uint256[](2);
        randomWordList[0] = randomNumExpected;
        jackpot.rawFulfillRandomWords(reqIdExpected, randomWordList);
        vm.stopPrank();

        uint256 randomNum = jackpot.getRandomNumberDrawnFromDrawingId(drawing_num);
        (drawing_num);
        uint256 reqId = jackpot.getVrfRequestIdFromDrawingId(drawing_num);
        assertEq(randomNum, randomNumExpected);
        assertEq(reqId, reqIdExpected);
    }
}
