import React, { useEffect, useState } from 'react';
import { Alchemy } from "alchemy-sdk";

const alchemy = new Alchemy({
  apiKey: "YOUR_ALCHEMY_API_KEY",
  network: "YOUR_NETWORK"
});

function App() {
  const [highestBid, setHighestBid] = useState(0);
  const [highestBidder, setHighestBidder] = useState("");
  const [auctionEndTime, setAuctionEndTime] = useState(0);
  const [buyItNowPrice, setBuyItNowPrice] = useState(0);
  const [creator, setCreator] = useState("");
  const [balance, setBalance] = useState(0);

  useEffect(() => {
    async function fetchData() {
      const highestBidResult = await alchemy.core.call({
        to: "YOUR_CONTRACT_ADDRESS",
        data: "0x...",
      });
      setHighestBid(highestBidResult);

      const highestBidderResult = await alchemy.core.call({
        to: "YOUR_CONTRACT_ADDRESS",
        data: "0x...",
      });
      setHighestBidder(highestBidderResult);

      const auctionEndTimeResult = await alchemy.core.call({
        to: "YOUR_CONTRACT_ADDRESS",
        data: "0x...",
      });
      setAuctionEndTime(auctionEndTimeResult);

      const buyItNowPriceResult = await alchemy.core.call({
        to: "YOUR_CONTRACT_ADDRESS",
        data: "0x...",
      });
      setBuyItNowPrice(buyItNowPriceResult);

      const creatorResult = await alchemy.core.call({
        to: "YOUR_CONTRACT_ADDRESS",
        data: "0x...",
      });
      setCreator(creatorResult);

      const balanceResult = await alchemy.core.call({
        to: "YOUR_CONTRACT_ADDRESS",
        data: "0x...",
      });
      setBalance(balanceResult);
    }

    fetchData();
  }, []);

  return (
    <div>
      <h1>Highest Bid: {highestBid}</h1>
      <h1>Highest Bidder: {highestBidder}</h1>
      <h1>Auction End Time: {auctionEndTime}</h1>
      <h1>Buy It Now Price: {buyItNowPrice}</h1>
      <h1>Creator: {creator}</h1>
      <h1>Balance: {balance}</h1>
    </div>
  );
}

export default App;
