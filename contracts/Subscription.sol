// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Subscription {
    struct Subscriber {
        uint64 nextPayment; // smaller type to reduce storage
        bool active;
    }

    address payable public immutable provider;
    uint96 public immutable amount; // smaller type, fits most use cases
    uint32 public immutable period; // seconds per period, small range

    mapping(address => Subscriber) public subscribers;

    event Subscribed(address indexed user, uint64 nextPayment);
    event Payment(address indexed user, uint96 amount, uint64 date);
    event Canceled(address indexed user);

    constructor(uint96 _amount, uint32 _period) payable {
        require(_amount > 0 && _period > 0, "Invalid params");
        provider = payable(msg.sender);
        amount = _amount;
        period = _period;
    }

    function subscribe() external payable {
        require(msg.value == amount, "Incorrect payment");
        Subscriber storage sub = subscribers[msg.sender];
        sub.active = true;
        sub.nextPayment = uint64(block.timestamp + period);

        emit Subscribed(msg.sender, sub.nextPayment);
    }

    function pay() external payable {
        Subscriber storage sub = subscribers[msg.sender];
        require(sub.active, "Not active");
        require(block.timestamp >= sub.nextPayment, "Not due yet");
        require(msg.value == amount, "Incorrect amount");

        sub.nextPayment = uint64(block.timestamp + period);
        provider.transfer(msg.value);

        emit Payment(msg.sender, amount, uint64(block.timestamp));
    }

    function cancel() external {
        Subscriber storage sub = subscribers[msg.sender];
        require(sub.active, "Not active");
        sub.active = false;

        emit Canceled(msg.sender);
    }
}
