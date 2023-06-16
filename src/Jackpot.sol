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

contract Jackpot is VRFConsumerBaseV2, AccessControl {
    using SafeERC20 for IERC20;

    address public immutable USDC;
    VRFCoordinatorV2Interface public immutable VRF_COODINATOR;

    bytes32 public keyHash;
    uint32 public callbackGasLimit;
    uint64 public subscriptionId;
    uint16 public requestConfirmations;

    bytes32 public constant RAFFLER_ROLE = keccak256("RAFFLER_ROLE");

    uint256 public raffleCount;

    struct RaffleData {
        mapping(address => uint256) userXP;
        address[] users;
        uint256[] prizeAmounts;
        bool isComplete;
    }

    /// @dev map raffleID to RaffleData
    mapping(uint256 => RaffleData) private raffles;

    /// @dev map vrfRequestId to raffleID
    mapping(uint256 => uint256) private vrfRequests;

    constructor(
        address _usdc,
        bytes32 _keyHash,
        uint32 _callbackGasLImit,
        uint64 _subscriptionId,
        uint16 _requestConfirmations,
        address _vrfCoordinator
    ) VRFConsumerBaseV2(_vrfCoordinator) {
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

    // TODO: complete this function add edit functions to edit everything at once and one thing at a time with right validation (checking id exists, raffle isn't done, etc)
    function createNewRaffle(
        address[] memory _users, uint256[] memory _orderedUserXp, uint256[] memory _prizeAmounts
    ) external
        onlyRole(RAFFLER_ROLE) {
            require(
                _users.length == _orderedUserXp.length,
                "Jackpot::createNewRaffle: The amount of users and orderedUserXP must be the same"
            );
            uint256 raffleId = raffleCount;
            raffleCount++;
            RaffleData storage raffle = raffles[raffleId];
            raffle.users = _users;
            raffle.prizeAmounts = _prizeAmounts;
            for (uint256 i = 0; i < _users.length; i++) {
                raffle.userXP[_users[i]] = _orderedUserXp[i];
            }
        }



    function setupRaffle(address[] memory _users, uint256[] memory _orderedUserXp, uint256[] memory _prizeAmounts)
        external
        onlyRole(RAFFLER_ROLE)
    {
        uint256 requestId = VRF_COODINATOR.requestRandomWords(
            keyHash, subscriptionId, requestConfirmations, callbackGasLimit, uint32(_prizeAmounts.length)
        );
        raffles[requestId].prizeAmounts = _prizeAmounts;
        raffles[requestId].users = _users;
        for (uint256 i = 0; i < _users.length; i++) {
            raffles[requestId].userXP[_users[i]] = _orderedUserXp[i];
        }
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual override {
        for (uint256 i = 0; i < randomWords.length; i++) {
            // TODO: fix
            uint256 randomNum = (randomWords[i] % getRaffleUpperLimitXP(requestId)) + 1;
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

    function getRaffleUserXp(uint256 _requestId, address _user) external view returns (uint256) {
        return raffles[_requestId].userXP[_user];
    }

    function getRaffleUsers(uint256 _requestId) external view returns (address[] memory) {
        return raffles[_requestId].users;
    }

    function getRafflePrizeAmounts(uint256 _requestId) external view returns (uint256[] memory) {
        return raffles[_requestId].prizeAmounts;
    }

    function getRaffleUpperLimitXP(uint256 _requestId) public view returns (uint256) {
        RaffleData storage raffle = raffles[_requestId];
        address lastUser = raffle.users[raffle.users.length - 1];
        return raffle.userXP[lastUser];
    }
}
