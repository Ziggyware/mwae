// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ZillennialMemeopolis is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIds;
    mapping (uint256 => uint256) private _tokenPrice;
    mapping (uint256 => bool) private _listedMap;

    address payable creator;

    constructor() ERC721("ZillennialMemeopolis", "ZIMO") {
        creator = payable(msg.sender);
    }

    function mintNFT(address recipient, string memory tokenURI, uint256 price)
        public onlyOwner
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);
        _tokenPrice[newItemId] = price;

        return newItemId;
    }

    function listToken(uint256 tokenId, uint256 price) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        _tokenPrice[tokenId] = price;
        _listedMap[tokenId] = true;
    }

    function delistToken(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        _listedMap[tokenId] = false;
    }

    function buyToken(uint256 tokenId) public payable {
        require(_listedMap[tokenId], "Token not for sale");
        require(msg.value >= _tokenPrice[tokenId], "Not enough Ether sent for this token");

        // calculate the fee and final price
        uint256 fee = _tokenPrice[tokenId].div(10);  // 10% fee
        uint256 priceAfterFee = _tokenPrice[tokenId].sub(fee);

        // transfer the token to the buyer
        _transfer(ownerOf(tokenId), msg.sender, tokenId);

        // transfer the funds to the seller and the creator
        payable(ownerOf(tokenId)).transfer(priceAfterFee);
        creator.transfer(fee);

        // delist the token
        _listedMap[tokenId] = false;
    }

    function getTokenPrice(uint256 tokenId) public view returns (uint256) {
        return _tokenPrice[tokenId];
    }

    function isTokenListed(uint256 tokenId) public view returns (bool) {
        return _listedMap[tokenId];
    }
}