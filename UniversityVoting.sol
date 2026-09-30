// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract UniversityVoting {
    address public owner;

    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }

    struct Election {
        uint256 id;
        string title;
        uint256 startTime;
        uint256 endTime;
        bool active;
        uint256[] candidateIds;
    }

    mapping(uint256 => Candidate) public candidates;
    mapping(uint256 => Election) public elections;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(address => bool) public registeredVoters;

    uint256 public nextCandidateId;
    uint256 public nextElectionId;

    event ElectionCreated(
        uint256 indexed electionId,
        string title,
        uint256 startTime,
        uint256 endTime
    );

    event VoteCast(
        uint256 indexed electionId,
        uint256 indexed candidateId,
        address indexed voter
    );

    event VoterRegistered(address indexed voter);
    event ElectionClosed(uint256 indexed electionId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not administrator");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function registerVoter(address voter) external onlyOwner {
        registeredVoters[voter] = true;
        emit VoterRegistered(voter);
    }

    function createElection(
        string calldata title,
        uint256 startTime,
        uint256 endTime
    ) external onlyOwner returns (uint256) {
        require(endTime > startTime, "Invalid voting period");

        uint256 electionId = nextElectionId++;
        Election storage e = elections[electionId];

        e.id = electionId;
        e.title = title;
        e.startTime = startTime;
        e.endTime = endTime;
        e.active = false;

        emit ElectionCreated(electionId, title, startTime, endTime);
        return electionId;
    }

    function addCandidate(
        uint256 electionId,
        string calldata name
    ) external onlyOwner returns (uint256) {
        require(elections[electionId].endTime > 0, "Election not found");

        uint256 candidateId = nextCandidateId++;
        candidates[candidateId] = Candidate(candidateId, name, 0);
        elections[electionId].candidateIds.push(candidateId);

        return candidateId;
    }

    function startElection(uint256 electionId) external onlyOwner {
        Election storage e = elections[electionId];
        require(block.timestamp >= e.startTime, "Too early");
        require(block.timestamp < e.endTime, "Election expired");
        e.active = true;
    }

    function closeElection(uint256 electionId) external onlyOwner {
        elections[electionId].active = false;
        emit ElectionClosed(electionId);
    }

    function vote(
        uint256 electionId,
        uint256 candidateId
    ) external {
        Election storage e = elections[electionId];

        require(registeredVoters[msg.sender], "Not registered");
        require(e.active, "Election inactive");
        require(block.timestamp >= e.startTime, "Voting not started");
        require(block.timestamp <= e.endTime, "Voting ended");
        require(!hasVoted[electionId][msg.sender], "Already voted");

        bool candidateExists = false;
        for (uint256 i = 0; i < e.candidateIds.length; i++) {
            if (e.candidateIds[i] == candidateId) {
                candidateExists = true;
                break;
            }
        }
        require(candidateExists, "Invalid candidate");

        hasVoted[electionId][msg.sender] = true;
        candidates[candidateId].voteCount++;

        emit VoteCast(electionId, candidateId, msg.sender);
    }
}