// SPDX-License-Identifier: MIT


pragma solidity^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./Auction.sol";

// ERC721 contract for the NFT
contract ZillennialMemeopolis is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    // Keeps track of total number of tokens minted
    Counters.Counter private _tokenIds;

    // Auction contract instance
    Auction public auction;

    // Creator of the contract
    address payable public creator;

    mapping (uint256 => string) private _tokenMetadataURIs;

    // Initialize the ERC721 token with a name and symbol, and the auction contract
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


    function _setMetadataURI(uint256 tokenId, string memory metadataURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenMetadataURIs[tokenId] = metadataURI;
    }

    function tokenMetadataURI(uint256 tokenId) public view virtual returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory _metadataURI = _tokenMetadataURIs[tokenId];
        
        return _metadataURI;
    }



    // Start an auction for a token
    function startAuction(uint256 tokenId, uint256 duration, uint256 buyItNowPrice) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");

        auction.start(tokenId, duration, buyItNowPrice);
    }

    // Bid on a token
    function bid(uint256 tokenId) public payable {
        auction.bid{value: msg.value}(tokenId);
    }

    // End an auction
    function endAuction(uint256 tokenId) public {
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
        return auction.getTokenPrice(tokenId);
    }


}