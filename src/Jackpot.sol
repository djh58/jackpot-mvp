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
     * @dev this role can setup drawings and draw numbers for them
     * @notice defaults to msg.sender, who can delegate others or revoke the role
     */
    bytes32 public constant RAFFLER_ROLE = keccak256("RAFFLER_ROLE");

    /// @dev this is the total number of drawings (zero-indexed), also acts as a uid for each
    uint256 public drawingCount;

    /// @dev ipfsHash contains all the details on participants, who are selected off-chain via randomNumberRaw
    struct DrawingData {
        string ipfsHash;
        uint256 vrfRequestId;
        uint256 randomNumberRaw;
    }

    /// @dev map uint256 drawingID to DrawingData
    mapping(uint256 => DrawingData) private drawings;

    /// @dev map uint256 vrfRequestId to uint256 drawingID. this allows us to quickly update the drawingData
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

    /// @dev this initializes the drawing, saying "hey, this is what the random number is gonna be used to select"
    function createNewDrawing(string calldata ipfsHash) external onlyRole(RAFFLER_ROLE) {
        uint256 drawingId = drawingCount;
        drawingCount++;
        DrawingData storage drawing = drawings[drawingId];
        drawing.ipfsHash = ipfsHash;
    }

    /// @dev updates drawing info in the event it is delayed and a new snapshot is made. cannot be updated after drawing, for fairness!
    function updateDrawingIpfsHash(string calldata ipfsHash, uint256 drawingId) external onlyRole(RAFFLER_ROLE) {
        DrawingData storage drawing = drawings[drawingId];
        if (drawing.vrfRequestId != 0 || drawing.randomNumberRaw != 0) {
            revert("Jackpot::setupDrawing: Drawing already drawn");
        }
        drawing.ipfsHash = ipfsHash;
    }

    /// @dev selects number which is saved by internal function, used to determine winner off-chain
    function drawNumber(uint256 drawingId) external onlyRole(RAFFLER_ROLE) {
        if (bytes(drawings[drawingId].ipfsHash).length == 0 || drawings[drawingId].vrfRequestId != 0) {
            revert("Jackpot::setupDrawing: Drawing either not set up or already drawn");
        }
        uint256 requestId = VRF_COODINATOR.requestRandomWords(
            keyHash, subscriptionId, requestConfirmations, callbackGasLimit, uint32(1)
        );
        drawings[drawingId].vrfRequestId = requestId;
    }

    /// @dev this is the callback function that is called by Chainlink VRF when the random number is drawn
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual override {
        for (uint256 i = 0; i < randomWords.length; i++) {
            uint256 drawingId = vrfRequests[requestId];
            DrawingData storage drawing = drawings[drawingId];
            drawing.randomNumberRaw = randomWords[i];
            if (i > 0) {
                revert("Jackpot::fulfillRandomWords: More than one random word returned");
            }
        }
    }

    /// @dev given a VRF request Id, returns the drawing Id. if zero then not affiliated with a drawing
    function getDrawingIdFromVrfRequestId(uint256 _requestId) external view returns (uint256) {
        return vrfRequests[_requestId];
    }

    /// @dev given a drawing Id, returns the VRF request Id. if zero then not drawn
    function getVrfRequestIdFromDrawingId(uint256 _drawingId) external view returns (uint256) {
        return drawings[_drawingId].vrfRequestId;
    }

    /// @dev given a drawing Id, returns the raw random number. if zero then not drawn
    function getRandomNumberDrawnFromDrawingId(uint256 _drawingId) external view returns (uint256) {
        return drawings[_drawingId].randomNumberRaw;
    }

    /// @dev given a drawing Id, returns the ipfs hash. if empty string than not initalized
    function getIpfsHashFromDrawingId(uint256 _drawingId) external view returns (string memory) {
        return drawings[_drawingId].ipfsHash;
    }

    /// @dev get zero-indexed total of drawings
    function getDrawingCount() external view returns (uint256) {
        return drawingCount;
    }
}
