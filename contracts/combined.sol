// SPDX-License-Identifier: MIT
pragma solidity^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Auction contract for managing auctions for each NFT
contract Auction is Ownable, ReentrancyGuard {
    using SafeMath for uint256;


    // AuctionItem struct to store information about each auction
    struct AuctionItem {
        uint256 highestBid;
        address payable highestBidder;
        uint256 auctionEndTime;
        uint256 buyItNowPrice;
        bool ended;
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

    function end(uint256 tokenId) public onlyOwner nonReentrant {
        AuctionItem storage auction = _auctions[tokenId];

        // Check if auction has ended
        require(block.timestamp >= auction.auctionEndTime, "Auction not yet ended");
        
        // Ensure there was at least one bid
        require(auction.highestBidder != address(0), "No bids received for this token");

        // Set ended to true to prevent re-entrancy
        auction.ended = true;

        emit AuctionEnded(tokenId, auction.highestBidder, auction.highestBid);

        // Transfer the final bid amount to the owner and the creator's fee
        uint256 creatorFee = auction.highestBid.mul(1).div(100);
        (bool sent, ) = owner().call{value: auction.highestBid.sub(creatorFee)}("");
        require(sent, "Failed to send Ether to the owner");

        // Send the creator's fee
        (sent, ) = _creator.call{value: creatorFee}("");
        require(sent, "Failed to send Ether to the creator");

        // Delete the auction from the mapping
        delete _auctions[tokenId];

        // Set ended back to false
        auction.ended = false;
    }

    bool private _mutex;

    // Start an auction for a token
    function start(uint256 tokenId, uint256 duration, uint256 buyItNowPrice) public onlyOwner nonReentrant {
        require(_auctions[tokenId].highestBidder == address(0), "Auction already exists for this token");
        require(duration > 0, "Duration must be greater than 0");
        require(buyItNowPrice >= 0, "BuyItNowPrice must be non-negative");

        // Set up new auction
        _auctions[tokenId] = AuctionItem(
        {
            highestBid: 0, 
            highestBidder: payable(address(0)),
            auctionEndTime: block.timestamp.add(duration),
            buyItNowPrice: buyItNowPrice,
            ended: false
        });
        
        emit AuctionStarted(tokenId, _auctions[tokenId].auctionEndTime, buyItNowPrice);
    }

    // Place a bid on an auction
    function bid(uint256 tokenId) public payable nonReentrant {
        AuctionItem storage auction = _auctions[tokenId];

        // Ensure auction has not ended
        require(block.timestamp < auction.auctionEndTime, "Auction already ended");
        require(!auction.ended, "Auction already ended");

        // Ensure new bid exceeds the highest bid
        require(msg.value > auction.highestBid, "There already is a higher bid");

        // Ensure mutex is not locked
        require(!_mutex, "Re-entrancy not allowed");

        // Lock mutex
        _mutex = true;

        // Return funds to the previous highest bidder and transfer the creator's fee
        if (auction.highestBid != 0 && 
            auction.highestBidder != address(0) && 
            auction.highestBidder != msg.sender && 
            !auction.ended && 
            block.timestamp < auction.auctionEndTime) {
            uint256 creatorFee = auction.highestBid.mul(1).div(100);

            // Set ended to true to prevent re-entrancy
            auction.ended = true;

            // Return the bid to the previous highest bidder minus the creator's fee
            (bool sent, ) = auction.highestBidder.call{value: auction.highestBid.sub(creatorFee)}("");
            require(sent, "Failed to send Ether back to the previous highest bidder");

            // Set ended back to false
            auction.ended = false;
        }

        // Set new highest bid
        auction.highestBid = msg.value;
        auction.highestBidder = payable(msg.sender);

        emit BidReceived(tokenId, msg.sender, msg.value);

        // If the bid is equal or higher than the buy it now price, end the auction
        if (msg.value >= auction.buyItNowPrice) {
            end(tokenId);
        }

        // Unlock mutex
        _mutex = false;
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

// ERC721 contract for the NFT
contract ZillennialMemeopolis is ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // Keeps track of total number of tokens minted
    Counters.Counter private _tokenIds;

    // Auction contract instance
    Auction public auction;

    // Creator of the contract
    address payable public creator;

    mapping (uint256 => string) private _tokenMetadataURIs;

    // Constructor that sets the creator of the contract and the Auction contract
    constructor(address payable _auction) ERC721("ZillennialMemeopolis", "ZIMO") {
        creator = payable(msg.sender);
        auction = Auction(_auction);
    }

    // Mint a new NFT token
    function mintNFT(address recipient, string memory tokenURI, string memory metadataURI) public onlyOwner returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        // Mint the NFT to the recipient
        _mint(recipient, newItemId);

        // Set the tokenURI and metadataURI
        _setTokenURI(newItemId, tokenURI);
        _setMetadataURI(newItemId, metadataURI);

        return newItemId;
    }

    // Function to set the metadata URI of a token
    function _setMetadataURI(uint256 tokenId, string memory metadataURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenMetadataURIs[tokenId] = metadataURI;
    }

    // Function to get the metadata URI of a token
    function tokenMetadataURI(uint256 tokenId) public view virtual returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory _metadataURI = _tokenMetadataURIs[tokenId];
        
        return _metadataURI;
    }



    // Start an auction for a token
    function startAuction(uint256 tokenId, uint256 duration, uint256 buyItNowPrice) public nonReentrant {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        require(_exists(tokenId), "ERC721Metadata: startAuction for nonexistent token");
        auction.start(tokenId, duration, buyItNowPrice);
    }

    bool private _bidMutex = false;
    // Bid on a token
    function bid(uint256 tokenId) public payable nonReentrant {
        require(_exists(tokenId), "ERC721Metadata: bid on nonexistent token");
        require(_bidMutex == false, "ERC721Metadata: bid mutex is locked");
        
        _bidMutex = true;
        auction.bid{value: msg.value}(tokenId);
        _bidMutex = false;
    }

    // End an auction
    function endAuction(uint256 tokenId) public nonReentrant {
        require(_exists(tokenId), "ERC721Metadata: endAuction on nonexistent token");
        auction.end(tokenId);
    }

    // Withdraw funds from the auction contract
    function withdrawAuctionFunds() public onlyOwner {
        auction.withdraw();
    }

    // Withdraw funds from the contract
    function withdrawFunds() public onlyOwner {
        creator.transfer(address(this).balance);
    }

    // Get the balance of the contract
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Get the price
    function getTokenPrice(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "ERC721Metadata: getTokenPrice on nonexistent token");
        return auction.getTokenPrice(tokenId);
    }


}