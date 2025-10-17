// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Escrow {

    enum State {
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
        uint indexed dealId,
        address indexed buyer,
        address seller,
        address arbiter,
        uint amount
    );
    event FundsReleased(uint indexed dealId, address indexed recipient, uint amount);
    event RefundProcessed(uint indexed dealId, address indexed recipient, uint amount);

    // --- Modifiers for Reusable Access Control ---

    modifier onlyBuyer(uint _dealId) {
        require(msg.sender == deals[_dealId].buyer, "Only buyer can perform this action");
        _;
    }

    modifier onlyBuyerOrArbiter(uint _dealId) {
        Deal storage deal = deals[_dealId];
        require(
            msg.sender == deal.buyer || msg.sender == deal.arbiter,
            "Only buyer or arbiter can perform this action"
        );
        _;
    }

    modifier inState(uint _dealId, State _expectedState) {
        require(deals[_dealId].state == _expectedState, "Deal is not in the correct state");
        _;
    }

    // --- Core Functions ---

    /**
     * @dev Creates a new escrow deal. Funds are deposited immediately.
     * @param _seller The address that will receive funds upon completion.
     * @param _arbiter The address authorized to approve refunds.
     */
    function createDeal(address _seller, address _arbiter) external payable {
        require(msg.value > 0, "Payment required to create a deal");
        require(_seller != address(0) && _arbiter != address(0), "Invalid addresses provided");

        // Use unchecked for efficient counter increment (safe from overflow).
        unchecked {
            dealCount++;
        }

        deals[dealCount] = Deal({
            buyer: msg.sender,
            seller: _seller,
            arbiter: _arbiter,
            amount: msg.value,
            state: State.AWAITING_DELIVERY
        });

        emit DealCreated(dealCount, msg.sender, _seller, _arbiter, msg.value);
    }

    /**
     * @dev Confirms successful delivery, releases funds to the seller.
     * @param _dealId The ID of the deal to complete.
     */
    function confirmDelivery(uint _dealId) 
        external
        onlyBuyer(_dealId)
        inState(_dealId, State.AWAITING_DELIVERY)
    {
        Deal storage deal = deals[_dealId];
        deal.state = State.COMPLETE;

        // Use .call{} for safe Ether transfer and full gas usage (recommended over .transfer)
        (bool success, ) = payable(deal.seller).call{value: deal.amount}("");
        require(success, "Ether transfer failed");

        emit FundsReleased(_dealId, deal.seller, deal.amount);
    }

    /**
     * @dev Refunds the deposited amount to the buyer. Can only be called by the buyer or arbiter.
     * @param _dealId The ID of the deal to refund.
     */
    function refund(uint _dealId) 
        external
        onlyBuyerOrArbiter(_dealId)
        inState(_dealId, State.AWAITING_DELIVERY)
    {
        Deal storage deal = deals[_dealId];
        deal.state = State.REFUNDED;

        // Use .call{} for safe Ether transfer
        (bool success, ) = payable(deal.buyer).call{value: deal.amount}("");
        require(success, "Ether transfer failed");

        emit RefundProcessed(_dealId, deal.buyer, deal.amount);
    }
}
