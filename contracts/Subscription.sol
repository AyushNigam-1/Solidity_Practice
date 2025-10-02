// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Subscription {
    struct Plan {
        uint amount; // amount per period
        uint period; // seconds between payments
    }

    struct Subscriber {
        uint nextPayment; // timestamp of next payment due
        bool active;
    }

    address public provider;
    Plan public plan;
    mapping(address => Subscriber) public subscribers;

    event Subscribed(address indexed user, uint nextPayment);
    event Payment(address indexed user, uint amount, uint date);
    event Canceled(address indexed user);

    modifier onlyProvider() {
        require(msg.sender == provider, "Not provider");
        _;
    }

    constructor(uint _amount, uint _period) {
        require(_amount > 0, "Invalid amount");
        require(_period > 0, "Invalid period");
        provider = msg.sender;
        plan = Plan(_amount, _period);
    }

    function subscribe() external payable {
        require(msg.value == plan.amount, "Must pay exact amount");
        Subscriber storage sub = subscribers[msg.sender];
        sub.active = true;
        sub.nextPayment = block.timestamp + plan.period;

        emit Subscribed(msg.sender, sub.nextPayment);
    }

    function pay() external payable {
        Subscriber storage sub = subscribers[msg.sender];
        require(sub.active, "Not subscribed");
        require(block.timestamp >= sub.nextPayment, "Not due yet");
        require(msg.value == plan.amount, "Incorrect payment");

        sub.nextPayment = block.timestamp + plan.period;
        payable(provider).transfer(msg.value);

        emit Payment(msg.sender, msg.value, block.timestamp);
    }

    function cancel() external {
        Subscriber storage sub = subscribers[msg.sender];
        require(sub.active, "Not active");
        sub.active = false;

        emit Canceled(msg.sender);
    }
}
