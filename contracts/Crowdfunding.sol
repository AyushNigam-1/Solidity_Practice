// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Crowdfunding {
    struct Campaign {
        address payable creator;
        string description;
        uint256 goal;
        uint256 deadline;
        uint256 fundsRaised;
        bool withdrawn;
        mapping(address => uint256) contributions;
    }

    Campaign[] public campaigns;

    event CampaignCreated(
        uint256 indexed campaignId,
        address indexed creator,
        uint256 goal,
        uint256 deadline
    );
    event Funded(
        uint256 indexed campaignId,
        address indexed contributor,
        uint256 amount
    );
    event Withdrawn(uint256 indexed campaignId, uint256 amount);
    event Refunded(
        uint256 indexed campaignId,
        address indexed contributor,
        uint256 amount
    );

    function createCampaign(
        string memory description,
        uint256 goal,
        uint256 durationInDays
    ) public {
        require(goal > 0, "Goal must be positive");
        require(durationInDays > 0, "Duration must be > 0");

        Campaign storage c = campaigns.push();
        c.creator = payable(msg.sender);
        c.description = description;
        c.goal = goal;
        c.deadline = block.timestamp + (durationInDays * 1 days);

        emit CampaignCreated(
            campaigns.length - 1,
            msg.sender,
            goal,
            c.deadline
        );
    }

    function fund(uint256 campaignId) public payable {
        Campaign storage c = campaigns[campaignId];
        require(block.timestamp < c.deadline, "Campaign ended");
        require(msg.value > 0, "Contribution must be > 0");

        c.contributions[msg.sender] += msg.value;
        c.fundsRaised += msg.value;

        emit Funded(campaignId, msg.sender, msg.value);
    }

    /// @notice Creator withdraws if goal is met
    function withdraw(uint256 campaignId) public {
        Campaign storage c = campaigns[campaignId];
        require(msg.sender == c.creator, "Not creator");
        require(block.timestamp >= c.deadline, "Campaign not ended");
        require(c.fundsRaised >= c.goal, "Goal not reached");
        require(!c.withdrawn, "Already withdrawn");

        c.withdrawn = true;
        uint256 amount = c.fundsRaised;
        c.creator.transfer(amount);

        emit Withdrawn(campaignId, amount);
    }

    /// @notice Contributors can claim refund if goal not met
    function refund(uint256 campaignId) public {
        Campaign storage c = campaigns[campaignId];
        require(block.timestamp >= c.deadline, "Campaign not ended");
        require(c.fundsRaised < c.goal, "Goal was met");

        uint256 contributed = c.contributions[msg.sender];
        require(contributed > 0, "Nothing to refund");

        c.contributions[msg.sender] = 0;
        payable(msg.sender).transfer(contributed);

        emit Refunded(campaignId, msg.sender, contributed);
    }
}
