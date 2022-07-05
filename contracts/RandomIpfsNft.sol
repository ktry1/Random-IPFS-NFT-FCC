// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

error RandomIpfsNft__AlreadyInitialized();
error RandomIpfsNft__NeedMoreETHSent();
error RandomIpfsNft__RangeOutOfBounds();

contract RandomIpfsNft is ERC721URIStorage, VRFConsumerBaseV2, Ownable {
    //Type Declaration
    enum Color {
        MULTICOLOR,
        PINK,
        BLUE
    }

    //Contract VRF Variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // NFT Variables
    uint256 private i_mintFee;
    uint256 public s_tokenCounter;
    mapping(uint256 => Color) private s_tokenIdToColor;
    uint256 internal constant MAX_CHANCE_VALUE = 100;
    string[] internal s_sunTokenUris;
    bool private s_initialized;

    // VRF Helpers
    mapping(uint256 => address) public s_requestIdToSender;

     // Events
    event NftRequested(uint256 indexed requestId, address requester);
    event NftMinted(Color color, address minter);

    constructor( address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint256 mintFee,
        uint32 callbackGasLimit,
        string[3] memory sunTokenUris) 
    ERC721("Cool suns NFT", "CSN")
    VRFConsumerBaseV2(vrfCoordinatorV2)
    {
   i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
   i_gasLane = gasLane;
   i_subscriptionId = subscriptionId;
   i_mintFee = mintFee;
   i_callbackGasLimit = callbackGasLimit;
   _initializeContract(sunTokenUris);
    }


    function requestNft() public payable returns (uint256 requestId) {
    if (msg.value < i_mintFee) {
        revert RandomIpfsNft__NeedMoreETHSent();
    }
    requestId = i_vrfCoordinator.requestRandomWords(
        i_gasLane,
        i_subscriptionId,
        REQUEST_CONFIRMATIONS,
        i_callbackGasLimit,
        NUM_WORDS
    );

    s_requestIdToSender[requestId] = msg.sender;
    emit NftRequested(requestId, msg.sender);
}

 function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        address sunOwner = s_requestIdToSender[requestId];
        uint256 newItemId = s_tokenCounter;
        s_tokenCounter = s_tokenCounter + 1;
        uint256 moddedRng = randomWords[0] % MAX_CHANCE_VALUE;
        Color sunColor = getColorFromModdedRng(moddedRng);
        _safeMint(sunOwner, newItemId);
        _setTokenURI(newItemId, s_sunTokenUris[uint256(sunColor)]);
        emit NftMinted(sunColor, sunOwner);
    }

 function getColorFromModdedRng(uint256 moddedRng) public pure returns (Color) {
        uint256 cumulativeSum = 0;
        uint256[3] memory chanceArray = getChanceArray();
        for (uint256 i = 0; i < chanceArray.length; i++) {
            // if (moddedRng >= cumulativeSum && moddedRng < cumulativeSum + chanceArray[i]) {
            if (moddedRng >= cumulativeSum && moddedRng < chanceArray[i]) {
                return Color(i);
            }
            // cumulativeSum = cumulativeSum + chanceArray[i];
            cumulativeSum = chanceArray[i];
        }
        revert RandomIpfsNft__RangeOutOfBounds();
    }

function _initializeContract(string[3] memory sunTokenUris) private {
        if (s_initialized) {
            revert RandomIpfsNft__AlreadyInitialized();
        }
        s_sunTokenUris = sunTokenUris;
        s_initialized = true;
    }

    function getChanceArray() public pure returns (uint256[3] memory) {
        return [10, 50, MAX_CHANCE_VALUE];
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }

    function getMintFee() public view returns (uint256) {
        return i_mintFee;
    }

    function getSunTokenUris(uint256 index) public view returns (string memory) {
        return s_sunTokenUris[index];
    }

    function getInitialized() public view returns (bool) {
        return s_initialized;
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }
}
