// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleVoting {
    struct Proposal {
        string description;
        uint256 voteCount;
    }

    Proposal[] public proposals;
    mapping(address => bool) public hasVoted;

    event ProposalCreated(uint256 indexed proposalId, string description);
    event Voted(address indexed voter, uint256 indexed proposalId);

    function createProposal(string memory description) public {
        proposals.push(Proposal({description: description, voteCount: 0}));
        emit ProposalCreated(proposals.length - 1, description);
    }

    function vote(uint256 proposalId) public {
        require(!hasVoted[msg.sender], "You already voted!");
        require(proposalId < proposals.length, "Invalid proposal");

        proposals[proposalId].voteCount++;
        hasVoted[msg.sender] = true;

        emit Voted(msg.sender, proposalId);
    }

    function getWinningProposal() public view returns (uint256 winningId) {
        uint256 maxVotes = 0;
        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > maxVotes) {
                maxVotes = proposals[i].voteCount;
                winningId = i;
            }
        }
    }
}
