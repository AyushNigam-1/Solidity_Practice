// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TipJar {
    address public owner;

    event Tipped(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function tip() external payable {
        require(msg.value > 0, "Send ETH to tip");
        emit Tipped(msg.sender, msg.value);
    }

    function withdraw() external {
        require(msg.sender == owner, "Not the owner");
        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw");
        payable(owner).transfer(balance);
        emit Withdrawn(owner, balance);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
