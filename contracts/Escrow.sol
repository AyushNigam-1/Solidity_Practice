// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Escrow {
    enum State {
        AWAITING_PAYMENT,
        AWAITING_DELIVERY,
        COMPLETE,
        REFUNDED
    }

    struct Deal {
        address buyer;
        address seller;
        address arbiter;
        uint amount;
        State state;
    }

    uint public dealCount;
    mapping(uint => Deal) public deals;

    event DealCreated(
        uint dealId,
        address buyer,
        address seller,
        address arbiter,
        uint amount
    );
    event PaymentDeposited(uint dealId, uint amount);
    event DeliveryConfirmed(uint dealId);
    event Refunded(uint dealId);

    function createDeal(address _seller, address _arbiter) external payable {
        require(msg.value > 0, "Payment required");
        require(
            _seller != address(0) && _arbiter != address(0),
            "Invalid addresses"
        );

        dealCount++;
        deals[dealCount] = Deal({
            buyer: msg.sender,
            seller: _seller,
            arbiter: _arbiter,
            amount: msg.value,
            state: State.AWAITING_DELIVERY
        });

        emit DealCreated(dealCount, msg.sender, _seller, _arbiter, msg.value);
    }

    function confirmDelivery(uint _dealId) external {
        Deal storage deal = deals[_dealId];
        require(msg.sender == deal.buyer, "Only buyer can confirm");
        require(deal.state == State.AWAITING_DELIVERY, "Not awaiting delivery");

        deal.state = State.COMPLETE;
        payable(deal.seller).transfer(deal.amount);

        emit DeliveryConfirmed(_dealId);
    }

    function refund(uint _dealId) external {
        Deal storage deal = deals[_dealId];
        require(
            msg.sender == deal.buyer || msg.sender == deal.arbiter,
            "Only buyer or arbiter can refund"
        );
        require(deal.state == State.AWAITING_DELIVERY, "Refund not allowed");

        deal.state = State.REFUNDED;
        payable(deal.buyer).transfer(deal.amount);

        emit Refunded(_dealId);
    }
}
