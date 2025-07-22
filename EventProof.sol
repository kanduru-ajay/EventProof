// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract EventProof is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    struct Event {
        uint256 id;
        string name;
        string description;
        string imageURI;
        uint256 startTime;
        uint256 endTime;
        address organizer;
        uint256 maxAttendees;
        uint256 claimedCount;
        bool isActive;
    }

    mapping(uint256 => Event) public events;
    mapping(uint256 => mapping(address => bool)) public hasClaimed;
    uint256 public eventCount;

    constructor() ERC721("EventProof POAP", "EPP") {}

    // Event organizers can create new events
    function createEvent(
        string memory name,
        string memory description,
        string memory imageURI,
        uint256 startTime,
        uint256 endTime,
        uint256 maxAttendees
    ) external {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(startTime < endTime, "Invalid time range");
        
        eventCount++;
        events[eventCount] = Event({
            id: eventCount,
            name: name,
            description: description,
            imageURI: imageURI,
            startTime: startTime,
            endTime: endTime,
            organizer: msg.sender,
            maxAttendees: maxAttendees,
            claimedCount: 0,
            isActive: true
        });
    }

    // Attendees can claim their POAP NFT
    function claimPOAP(uint256 eventId) external {
        require(eventId > 0 && eventId <= eventCount, "Invalid event ID");
        Event storage eventItem = events[eventId];
        
        require(eventItem.isActive, "Event is not active");
        require(block.timestamp >= eventItem.startTime && block.timestamp <= eventItem.endTime, "Event not in progress");
        require(!hasClaimed[eventId][msg.sender], "Already claimed");
        require(eventItem.claimedCount < eventItem.maxAttendees, "Event at capacity");
        
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        
        _safeMint(msg.sender, tokenId);
        hasClaimed[eventId][msg.sender] = true;
        eventItem.claimedCount++;
        
        emit POAPClaimed(eventId, msg.sender, tokenId);
    }

    // Event organizers can deactivate events
    function toggleEventActive(uint256 eventId, bool isActive) external {
        require(eventId > 0 && eventId <= eventCount, "Invalid event ID");
        require(events[eventId].organizer == msg.sender, "Not event organizer");
        events[eventId].isActive = isActive;
    }

    // Override tokenURI to include event information
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        
        // In a real implementation, you would return a properly formatted JSON URI
        // with metadata about the event and POAP
        return string(abi.encodePacked(
            "https://eventproof.app/api/token/",
            Strings.toString(tokenId)
        ));
    }

    event POAPClaimed(uint256 indexed eventId, address indexed attendee, uint256 tokenId);
    event EventCreated(uint256 indexed eventId, address indexed organizer, string name);
}