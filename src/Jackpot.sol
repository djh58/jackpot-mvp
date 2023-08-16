// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

/**
 * @title Jackpot MVP - VRF Client, Tracking of winner selection via IPFS
 * @author Dan Hepworth
 */

import "@chainlink/VRFConsumerBaseV2.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/access/AccessControl.sol";
import "@chainlink/interfaces/VRFCoordinatorV2Interface.sol";

contract Jackpot is VRFConsumerBaseV2, AccessControl {
    /// @dev these are Chainlink VRF configurations
    VRFCoordinatorV2Interface public immutable VRF_COODINATOR;
    bytes32 public keyHash;
    uint32 public callbackGasLimit;
    uint64 public subscriptionId;
    uint16 public requestConfirmations;

    /**
     * @dev this role can setup raffles and draw numbers for them
     * @notice defaults to msg.sender, who can delegate others or revoke the role
     */
    bytes32 public constant RAFFLER_ROLE = keccak256("RAFFLER_ROLE");

    /// @dev this is the total number of raffles (zero-indexed), also acts as a uid for each
    uint256 public raffleCount;

    /// @dev ipfsHash contains all the details on participants, who are selected off-chain via randomNumberRaw
    struct RaffleData {
        string ipfsHash;
        uint256 vrfRequestId;
        uint256 randomNumberRaw;
    }

    /// @dev map uint256 raffleID to RaffleData
    mapping(uint256 => RaffleData) private raffles;

    /// @dev map uint256 vrfRequestId to uint256 raffleID. this allows us to quickly update the raffleData
    mapping(uint256 => uint256) private vrfRequests;

    /// @dev deployer needs to input Chainlink configs, accessible via VRF GUI and docs
    constructor(
        bytes32 _keyHash,
        uint32 _callbackGasLImit,
        uint64 _subscriptionId,
        uint16 _requestConfirmations,
        address _vrfCoordinator
    ) VRFConsumerBaseV2(_vrfCoordinator) {
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
        require(requestConfirmations != _requestConfirmations, "Jackpot::setRequestConfirmations: set to unique value");
        requestConfirmations = _requestConfirmations;
    }

    /// @dev this initializes the raffle, saying "hey, this is what the random number is gonna be used to select"
    function createNewRaffle(string calldata ipfsHash) external onlyRole(RAFFLER_ROLE) {
        uint256 raffleId = raffleCount;
        raffleCount++;
        RaffleData storage raffle = raffles[raffleId];
        raffle.ipfsHash = ipfsHash;
    }

    /// @dev updates raffle info in the event it is delayed and a new snapshot is made. cannot be updated after drawing, for fairness!
    function updateRaffleIpfsHash(string calldata ipfsHash, uint256 raffleId) external onlyRole(RAFFLER_ROLE) {
        RaffleData storage raffle = raffles[raffleId];
        if (raffle.vrfRequestId != 0 || raffle.randomNumberRaw != 0) {
            revert("Jackpot::setupRaffle: Raffle already drawn");
        }
        raffle.ipfsHash = ipfsHash;
    }

    /// @dev selects number which is saved by internal function, used to determine winner off-chain
    function drawRaffle(uint256 raffleId) external onlyRole(RAFFLER_ROLE) {
        if (bytes(raffles[raffleId].ipfsHash).length == 0 || raffles[raffleId].vrfRequestId != 0) {
            revert("Jackpot::setupRaffle: Raffle either not set up or already drawn");
        }
        uint256 requestId = VRF_COODINATOR.requestRandomWords(
            keyHash, subscriptionId, requestConfirmations, callbackGasLimit, uint32(1)
        );
        raffles[raffleId].vrfRequestId = requestId;
    }

    /// @dev this is the callback function that is called by Chainlink VRF when the random number is drawn
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual override {
        for (uint256 i = 0; i < randomWords.length; i++) {
            uint256 raffleId = vrfRequests[requestId];
            RaffleData storage raffle = raffles[raffleId];
            raffle.randomNumberRaw = randomWords[i];
            if (i > 0) {
                revert("Jackpot::fulfillRandomWords: More than one random word returned");
            }
        }
    }

    /// @dev given a VRF request Id, returns the raffle Id. if zero then not affiliated with a raffle
    function getRaffleIdFromVrfRequestId(uint256 _requestId) external view returns (uint256) {
        return vrfRequests[_requestId];
    }

    /// @dev given a raffle Id, returns the VRF request Id. if zero then not drawn
    function getVrfRequestIdFromRaffleId(uint256 _raffleId) external view returns (uint256) {
        return raffles[_raffleId].vrfRequestId;
    }

    /// @dev given a raffle Id, returns the raw random number. if zero then not drawn
    function getRandomNumberDrawnFromRaffleId(uint256 _raffleId) external view returns (uint256) {
        return raffles[_raffleId].randomNumberRaw;
    }

    /// @dev given a raffle Id, returns the ipfs hash. if empty string than not initalized
    function getIpfsHashFromRaffleId(uint256 _raffleId) external view returns (string memory) {
        return raffles[_raffleId].ipfsHash;
    }

    /// @dev get zero-indexed total of raffles
    function getRaffleCount() external view returns (uint256) {
        return raffleCount;
    }
}
