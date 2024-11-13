// SPDX-License-Identifier: Public Domain
pragma solidity ^0.8.0;

contract Giveaway {
    address public owner;
    uint256 public totalDonations;
    uint256 public couponCount;
    mapping(address => uint256) public coupons;
    mapping(uint256 => address) public couponOwners;
    mapping(address => bool) public isWinner;
    bool public giveawayClosed = false;

    event DonationReceived(address indexed donor, uint256 amount, uint256 couponId);
    event WinnerAssigned(address indexed winner);
    event EtherClaimed(address indexed claimer, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier onlyWinner() {
        require(isWinner[msg.sender] == false, "Only a winner can claim the giveaway");
        _;
    }

    modifier whenGiveawayOpen() {
        require(!giveawayClosed, "Giveaway is closed");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function donate() external payable whenGiveawayOpen {
        require(msg.value > 0, "Donation must be greater than zero");

        totalDonations += msg.value;
        couponCount++;

        coupons[msg.sender]++;
        couponOwners[couponCount] = msg.sender;

        emit DonationReceived(msg.sender, msg.value, couponCount);
    }

    function assignWinner(address _winner) external onlyOwner {
        require(!giveawayClosed, "Giveaway is already closed.");
        // require(coupons[_winner] > 0, "Address must have at least one coupon");

        isWinner[_winner] = true;
        giveawayClosed = true; // Close the giveaway after assigning the winner

        emit WinnerAssigned(_winner);
    }

    function claim() external onlyWinner {
        uint256 amount = totalDonations;
        require(amount > 0, "No funds to claim");

        // Reset state before transferring to prevent reentrancy attacks
        totalDonations = 0;
        isWinner[msg.sender] = false;

        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");

        emit EtherClaimed(msg.sender, amount);
    }

    function getCouponCount(address _donor) external view returns (uint256) {
        return coupons[_donor];
    }

    function getPoolBalance() external view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable whenGiveawayOpen {
        require(msg.value > 0, "Donation must be greater than zero");

        totalDonations += msg.value;
        couponCount++;

        // Record the donor's coupon
        coupons[msg.sender]++;
        couponOwners[couponCount] = msg.sender;

        emit DonationReceived(msg.sender, msg.value, couponCount);
    }
}