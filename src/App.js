import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import './App.css';

// Import the contract ABI
import CombinedContract from './contracts/Combined.json';

function App() {
  const [contract, setContract] = useState(null);
  const [account, setAccount] = useState('');
  const [tokenId, setTokenId] = useState('');
  const [tokenPrice, setTokenPrice] = useState('');
  const [isListed, setIsListed] = useState(false);

  useEffect(() => {
    // Function to initialize the contract
    const initContract = async () => {
      try {
        // Connect to the Ethereum provider
        const provider = new ethers.providers.Web3Provider(window.ethereum);

        // Get the signer account
        const signer = provider.getSigner();

        // Get the network ID
        const networkId = await provider.getNetwork().then((network) => network.chainId);

        // Get the contract address from the contract JSON file
        const contractAddress = CombinedContract.networks[networkId].address;

        // Create a new contract instance
        const combinedContract = new ethers.Contract(contractAddress, CombinedContract.abi, signer);

        // Set the contract instance
        setContract(combinedContract);

        // Get the current account
        const currentAccount = await signer.getAddress();

        // Set the account
        setAccount(currentAccount);
      } catch (error) {
        console.error('Error initializing contract:', error);
      }
    };

    // Initialize the contract
    initContract();
  }, []);

  // Function to handle buying an NFT
  const handleBuyNFT = async () => {
    try {
      // Call the buy function in the contract
      await contract.buy(tokenId, { value: tokenPrice });

      // Refresh the token details
      await getTokenDetails();
    } catch (error) {
      console.error('Error buying NFT:', error);
    }
  };

  // Function to handle selling an NFT
  const handleSellNFT = async () => {
    try {
      // Call the sell function in the contract
      await contract.sell(tokenId, tokenPrice);

      // Refresh the token details
      await getTokenDetails();
    } catch (error) {
      console.error('Error selling NFT:', error);
    }
  };

  // Function to handle listing an NFT
  const handleListNFT = async () => {
    try {
      // Call the list function in the contract
      await contract.list(tokenId, tokenPrice);

      // Refresh the token details
      await getTokenDetails();
    } catch (error) {
      console.error('Error listing NFT:', error);
    }
  };

  // Function to handle de-listing an NFT
  const handleDelistNFT = async () => {
    try {
      // Call the delist function in the contract
      await contract.delist(tokenId);

      // Refresh the token details
      await getTokenDetails();
    } catch (error) {
      console.error('Error delisting NFT:', error);
    }
  };

  // Function to get the details of the token
  const getTokenDetails = async () => {
    try {
      // Call the getTokenPrice function in the contract
      const price = await contract.getTokenPrice(tokenId);

      // Call the getTokenListingStatus function in the contract
      const listed = await contract.getTokenListingStatus(tokenId);

      // Set the token price and listing status
      setTokenPrice(price.toString());
      setIsListed(listed);
    } catch (error) {
      console.error('Error getting token details:', error);
    }
  };

  return (
    <div className="App">
      <h1>NFT Marketplace</h1>
      <div>
        <label>Token ID:</label>
        <input type="text" value={tokenId} onChange={(e) => setTokenId(e.target.value)} />
      </div>
      <div>
        <label>Token Price:</label>
        <input type="text" value={tokenPrice} onChange={(e) => setTokenPrice(e.target.value)} />
      </div>
      <div>
        <button onClick={handleBuyNFT}>Buy NFT</button>
        <button onClick={handleSellNFT}>Sell NFT</button>
        {isListed ? (
          <button onClick={handleDelistNFT}>De-list NFT</button>
        ) : (
          <button onClick={handleListNFT}>List NFT</button>
        )}
      </div>
    </div>
  );
}

export default App;
