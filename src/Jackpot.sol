// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

/**
 * @title Jackpot MVP - USDC raffles
 * @author Dan Hepworth
 */

import "@chainlink/VRFConsumerBaseV2.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/access/AccessControl.sol";
import "@chainlink/interfaces/VRFCoordinatorV2Interface.sol";

/** TODO:
 * 1) Test the shit out of it 
 * 2) Make more efficient
 * 3) 
 */
contract Jackpot is VRFConsumerBaseV2, AccessControl {
    using SafeERC20 for IERC20;

    address immutable USDC; 
    VRFCoordinatorV2Interface immutable VRF_COODINATOR; 

    bytes32 public keyHash;
    uint32 public callbackGasLimit;
    uint64 public subscriptionId;
    uint16 public requestConfirmations;

    bytes32 RAFFLER_ROLE = keccak256("RAFFLER_ROLE");

    struct RaffleData {
        mapping (address => uint256) userXP;
        address[] users;
        uint256[] prizeAmounts;
        uint256 upperLimitXP;
    }

    mapping(uint256 => RaffleData) raffles;
    constructor(address _usdc, bytes32 _keyHash, uint32 _callbackGasLImit, uint64 _subscriptionId, uint16 _requestConfirmations, address _vrfCoordinator) VRFConsumerBaseV2(_vrfCoordinator) {
        USDC = _usdc;
        VRF_COODINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLImit;
        subscriptionId = _subscriptionId;
        requestConfirmations = _requestConfirmations;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(RAFFLER_ROLE, msg.sender);
    }

    function setKeyHash(bytes32 _keyHash) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(keyHash != _keyHash, "Jackpot::setKeyHash: This key hash is already set");
        keyHash = _keyHash;
    }

    function setSubscriptionId(uint64 _subscriptionId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(subscriptionId != _subscriptionId, "Jackpot::setSubscriptionId: This subscription id is already set");
        subscriptionId = _subscriptionId;
    }

    function setCallbackGasLimit(uint32 _gasLimit) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(callbackGasLimit != _gasLimit, "Jackpot::setCallbackGasLimit: This gas limit is already set");
        callbackGasLimit = _gasLimit;
    }

    function setRequestConfirmations(uint16 _requestConfirmations) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            requestConfirmations != _requestConfirmations,
            "Jackpot::setRequestConfirmations: This amount of confirmations is already set"
        );
        requestConfirmations = _requestConfirmations;
    }

    function setupRaffle(address[] calldata _users, uint256[] calldata _orderedUserXp, uint256[] calldata _prizeAmounts, uint256 _upperLimitXP) external {
        uint256 requestId = VRF_COODINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            uint32(_prizeAmounts.length)
        );
        raffles[requestId].prizeAmounts = _prizeAmounts;
        raffles[requestId].upperLimitXP = _upperLimitXP;
        for (uint256 i = 0; i < _users.length; i++) {
            raffles[requestId].userXP[_users[i]] = _orderedUserXp[i];
            raffles[requestId].users.push(_users[i]);
        }
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual override {
        for (uint256 i = 0; i < randomWords.length; i++) {
            uint256 randomNum = (randomWords[i] % raffles[requestId].upperLimitXP) + 1;
            uint256 prizeAmount = raffles[requestId].prizeAmounts[i];
            uint256 userXp;
            uint256 j; 
            address winner;
            while (userXp < randomNum) {
                winner = raffles[requestId].users[j];
                userXp = raffles[requestId].userXP[winner];
                j++;
            }
            IERC20(USDC).safeTransfer(winner, prizeAmount);
        }
    }
}
