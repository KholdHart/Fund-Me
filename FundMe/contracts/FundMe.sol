// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// We're importing the interface to get price feed data
// Note: The AggregatorV3Interface might be at a different location than what was in the video!
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

// Custom error saves gas compared to require statements with strings
error NotOwner();

contract FundMe {
    // Uses the PriceConverter library for uint256 - this lets us call library functions as methods on uint256
    using PriceConverter for uint256;

    // Keeps track of how much each address has funded
    mapping(address => uint256) public addressToAmountFunded;
    // Array to track all funders so we can loop through them later
    address[] public funders;

    // i_owner is marked with i_ to show it's immutable (set once, can't change)
    // immutable variables save gas compared to regular storage variables
    address public /* immutable */ i_owner;
    // constant variables are set at compile time and can't be changed - saves gas
    // 5 * 10^18 = 5 USD in wei with 18 decimals
    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;

    constructor() {
        // sets the contract deployer as the owner
        i_owner = msg.sender;
    }

    function fund() public payable {
        // Checks if the value sent meets minimum USD requirement
        // Will revert (cancel transaction and return gas) if not enough ETH sent
        require(msg.value.getConversionRate() >= MINIMUM_USD, "You need to spend more ETH!");
        // Alternative way to call without using the "using for" syntax
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        
        // Add the sent amount to funder's total
        addressToAmountFunded[msg.sender] += msg.value;
        // Add this address to our funders array
        funders.push(msg.sender);
    }

    // Function to test our price feed connection
    function getVersion() public view returns (uint256) {
        // Create interface instance with the Sepolia ETH/USD price feed address
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        return priceFeed.version();
    }

    // Custom function modifier - can be added to functions to run this code first
    modifier onlyOwner() {
        // Old way using require
        // require(msg.sender == owner);
        
        // New way using custom error - saves gas when it reverts
        if (msg.sender != i_owner) revert NotOwner();
        _; // this means "run the rest of the function code now"
    }

    // Only the owner can withdraw all funds from the contract
    function withdraw() public onlyOwner {
        // Loop through all funders to reset their funded amount
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            // Get the funder address at this position
            address funder = funders[funderIndex];
            // Reset their funded amount to 0
            addressToAmountFunded[funder] = 0;
        }
        
        // Reset the funders array to empty
        // new address[](0) creates new empty array with 0 elements
        funders = new address[](0);
        
        // 3 ways to send ETH: transfer, send, call
        
        // Option 1: transfer (2300 gas, throws error)
        // payable(msg.sender).transfer(address(this).balance);

        // Option 2: send (2300 gas, returns bool)
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // Option 3: call (forwards all gas or set gas, returns bool) - RECOMMENDED WAY
        // (bool callSuccess,) = means we're ignoring the second return value (bytes data)
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }
    
    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \
    //         yes  no
    //         /     \
    //    receive()?  fallback()
    //     /   \
    //   yes   no
    //  /        \
    //receive()  fallback()

    // fallback runs when function doesn't exist and data is sent
    fallback() external payable {
        // Auto-routes money to our fund function
        fund();
    }

    // receive runs when ETH is sent with no calldata
    receive() external payable {
        // Auto-routes money to our fund function
        fund();
    }
}

//according to the course, this wont be fully functional