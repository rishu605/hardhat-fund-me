// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./PriceConverter.sol";

contract FundMe {

    address immutable owner;

    using PriceConverter for uint256;

    uint256 public constant minimumUSD = 50*1e18;

    AggregatorV3Interface public priceFeed;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    error FundMe__Unauthorized(string message);

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    modifier onlyOwner() {
        // require(msg.sender == owner);
        if(msg.sender != owner) {
            revert FundMe__Unauthorized("Not Owner");
        }
        _;
    }

    function fund() public payable{
        // Set a minimum fund amount in USD

        // 1. How do we send ETH to this contract
        
        // Every transaction that we send will have the following fields:
        // 1. nonce - tx count for the account
        // 2. gas price - price per unit of gas in wei
        // 3. gas limit - max gas that this transaction can use
        // 4. to - address that the transaction is sent to
        // 5. value - amount of wei to send
        // 6. data - what to send to the 'to' address
        // 7. v,r,s - cryptographic components of the transaction signature

        require(msg.value.getConversionRate(priceFeed) >= minimumUSD, "Not enough Ether sent!");
        // require(PriceConverter.getConversionRate(msg.value) > minimumUSD, "Not enough Ether sent!"); //Alternate way
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner{
        for(uint i=0; i< funders.length; i++) {
            addressToAmountFunded[funders[i]] = 0;
        }
        // Resetting the funders array
        funders = new address[](0);

        // Withdraw funds to the caller
        // We can use either of:
        // 1. transfer - send token from the contract to msg.sender
        // can use 2300 gas only else it fails, it throws an error if it fails
        // automatically reverts if the transaction fails
        payable(msg.sender).transfer(address(this).balance);
        // 2. send - can use 2300 gas, 
        // If gas consumption is more than 2300, it fails
        // returns a bool value telling if the transaction is successful or failed 
        // have to use require() to check if the transaction succeeded
        bool success = payable(msg.sender).send(address(this).balance);
        require(success, "Ether send failed");
        // 3. call - forwards all gas so it does NOT have a capped gas
        // returns bool,
        // We can use this function to make low-level calls to any function without even having the ABI
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}