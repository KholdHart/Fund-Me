// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Importing Chainlink price feed interface to get ETH/USD exchange rate
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol"; 

// Library = reusable code that doesn't modify state
// Why is this a library and not abstract?
// - Libraries don't have state variables, can't inherit, can't be inherited
// - Libraries are deployed once and reused by contracts
// Why not an interface?
// - Interface is just function signatures, no implementations
// - We need actual code/logic here
library PriceConverter {
    // Gets the current ETH/USD price from Chainlink oracle
    // internal = only this contract and derived contracts can call
    // view = doesn't modify state
    function getPrice() internal view returns (uint256) {
        // Sepolia ETH / USD Address from Chainlink
        // https://docs.chain.link/data-feeds/price-feeds/addresses
        // Creating instance of the price feed at this specific address
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );
        
        // latestRoundData returns multiple values, we only want answer
        // Using destructuring to ignore other return values with commas
        // (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        
        // ETH/USD rate in 18 digit format
        // answer comes with 8 decimals, we multiply by 10^10 to get 18 decimals
        return uint256(answer * 10000000000);
    }

    // Converts ETH amount to USD value
    // Takes ETH amount as input and returns USD equivalent
    function getConversionRate(
        uint256 ethAmount
    ) internal view returns (uint256) {
        // Get the current ETH price first
        uint256 ethPrice = getPrice();
        
        // Calculate USD value by multiplying price by amount
        // ethPrice = ETH/USD price with 18 decimals
        // ethAmount = amount in wei (also with 18 decimals)
        // Need to divide by 10^18 to account for the decimal places
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        
        // Return the USD value of the ETH amount
        // Now we have USD value with 18 decimal places
        return ethAmountInUsd;
    }
}