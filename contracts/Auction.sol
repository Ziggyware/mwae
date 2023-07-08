// SPDX-License-Identifier: MIT

pragma solidity^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// An auction contract for NFT tokens
contract Auction is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct AuctionItem {
        uint256 highestBid;
        address payable highestBidder;
        uint256 auctionEndTime;
        uint256 buyItNowPrice;
    }

    // Mapping from token ID to its auction details
    mapping(uint256 => AuctionItem) private _auctions;

    // The creator of this contract, who gets a cut from each bid
    address payable private _creator;

    // Events for starting, bidding, and ending an auction
    event AuctionStarted(uint256 tokenId, uint256 endTime, uint256 buyItNowPrice);
    event BidReceived(uint256 tokenId, address bidder, uint256 amount);
    event AuctionEnded(uint256 tokenId, address winner, uint256 amount);

    // Initialize the creator
    constructor(address payable creator) {
        _creator = creator;
    }

    // Bidding function that allows users to place a bid on a token
    function bid(uint256 tokenId) public payable nonReentrant {
        AuctionItem storage auction = _auctions[tokenId];
        
        // Ensure auction has not ended
        require(block.timestamp <= auction.auctionEndTime, "Auction already ended");

        // Ensure new bid exceeds the highest bid
        require(msg.value > auction.highestBid, "There already is a higher bid");

        if (auction.highestBid != 0) {
            uint256 creatorFee = auction.highestBid.mul(1).div(100);

            // Return the bid to the previous highest bidder minus the creator's fee
            (bool sent, ) = auction.highestBidder.call{value: auction.highestBid.sub(creatorFee)}("");
            require(sent, "Failed to send Ether back to the previous highest bidder");

            // Send the creator's fee
            (sent, ) = _creator.call{value: creatorFee}("");
            require(sent, "Failed to send Ether to the creator");
        }

        // Set new highest bid
        auction.highestBid = msg.value;
        auction.highestBidder = payable(msg.sender);

        emit BidReceived(tokenId, msg.sender, msg.value);

        // If the bid is equal or higher than the buy it now price, end the auction
        if (msg.value >= auction.buyItNowPrice) {
            end(tokenId);
        }
    }

    // End the auction, and transfer the highest bid to the owner of the token
    function end(uint256 tokenId) public onlyOwner nonReentrant {
        AuctionItem storage auction = _auctions[tokenId];

        // Check if auction has ended
        require(block.timestamp >= auction.auctionEndTime, "Auction not yet ended");
        
        // Ensure there was at least one bid
        require(auction.highestBidder != address(0), "No bids received for this token");

        emit AuctionEnded(tokenId, auction.highestBidder, auction.highestBid);

        uint256 creatorFee = auction.highestBid.mul(1).div(100);

        // Send the highest bid to the owner, minus the creator's fee
        (bool sent, ) = owner().call{value: auction.highestBid.sub(creatorFee)}("");
        require(sent, "Failed to send Ether to the owner");

        // Send the creator's fee
        (sent, ) = _creator.call{value: creatorFee}("");
        require(sent, "Failed to send Ether to the creator");

        // Delete auction
        delete _auctions[tokenId];
    }

    // Start an auction for a token
    function start(uint256 tokenId, uint256 duration, uint256 buyItNowPrice) public onlyOwner nonReentrant {
        require(_auctions[tokenId].highestBidder == address(0), "Auction already exists for this token");
        require(duration > 0, "Duration must be greater than 0");
        require(buyItNowPrice >= 0, "BuyItNowPrice must be non-negative");

        // Set up new auction
        _auctions[tokenId] = AuctionItem({highestBid: 0, highestBidder: payable(address(0)), auctionEndTime: block.timestamp.add(duration), buyItNowPrice: buyItNowPrice });

        emit AuctionStarted(tokenId, _auctions[tokenId].auctionEndTime, buyItNowPrice);
    }

    // Get the token highest bid
    function getHighestBid(uint256 tokenId) public view returns(uint256) {
        AuctionItem storage auction = _auctions[tokenId];

        // If the auction has ended, return the highest bid
        if (block.timestamp >= auction.auctionEndTime) {
            return auction.highestBid;
        }

        // Otherwise, return 0
        return 0;
    }


    // Get the token highest bidder
    function getHighestBidder(uint256 tokenId) public view returns(address) {
        AuctionItem storage auction = _auctions[tokenId];

        // If the auction has ended, return the highest bidder
        if (block.timestamp >= auction.auctionEndTime) {
            return auction.highestBidder;
        }

        // Otherwise, return 0
        return address(0);
    }


    function getAuctionEndTime(uint256 tokenId) public view returns(uint256) {
        return _auctions[tokenId].auctionEndTime;
    }

    function getBuyItNowPrice(uint256 tokenId) public view returns(uint256) {
        return _auctions[tokenId].buyItNowPrice;
    }

    function getCreator() public view returns(address) {
        return _creator;
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    // Withdraw the contract balance
    function withdrawContractBalance() public onlyOwner {
        (bool sent, ) = owner().call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    // Withdraw the balance of the contract
    function withdraw() public onlyOwner {
        (bool sent, ) = owner().call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    // Fallback function
    receive() external payable {}


    // Get the token price
    function getTokenPrice(uint256 tokenId) public view returns(uint256) {
        AuctionItem storage auction = _auctions[tokenId];

        // If the auction has ended, return the highest bid
        if (block.timestamp >= auction.auctionEndTime) {
            return auction.highestBid;
        }

        // Otherwise, return the buy it now price
        return auction.buyItNowPrice;
    }

    // Get the token owner
    function getTokenOwner(uint256 tokenId) public view returns(address) {
        AuctionItem storage auction = _auctions[tokenId];

        // If the auction has ended, return the highest bidder
        if (block.timestamp >= auction.auctionEndTime) {
            return auction.highestBidder;
        }

        // Otherwise, return the owner of the token
        return owner();
    }

    // Get the token auction end time
    function getTokenAuctionEndTime(uint256 tokenId) public view returns(uint256) {
        AuctionItem storage auction = _auctions[tokenId];

        // If the auction has ended, return the auction end time
        if (block.timestamp >= auction.auctionEndTime) {
            return auction.auctionEndTime;
        }

        // Otherwise, return 0
        return 0;
    }

    // Get the token auction ended boolean
    function getTokenAuctionEnded(uint256 tokenId) public view returns(bool) {
        AuctionItem storage auction = _auctions[tokenId];

        // If the auction has ended, return true
        if (block.timestamp >= auction.auctionEndTime) {
            return true;
        }

        // Otherwise, return false
        return false;
    }

    // Get the token buy it now price
    function getTokenBuyItNowPrice(uint256 tokenId) public view returns(uint256) {
        AuctionItem storage auction = _auctions[tokenId];

        // If the auction has ended, return 0
        if (block.timestamp >= auction.auctionEndTime) {
            return 0;
        }

        // Otherwise, return the buy it now price
        return auction.buyItNowPrice;
    }

    // Get the token creator fee
    function getTokenCreatorFee(uint256 tokenId) public view returns(uint256) {
        AuctionItem storage auction = _auctions[tokenId];

        // If the auction has ended, return the creator fee
        if (block.timestamp >= auction.auctionEndTime) {
            return auction.highestBid.mul(1).div(100);
        }

        // Otherwise, return 0
        return 0;
    }




}