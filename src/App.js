import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { ZillennialMemeopolisABI } from './contracts/ZillennialMemeopolisABI'; // Import the ABI of the ZillennialMemeopolis contract

function App() {
  const [contract, setContract] = useState(null);
  const [tokenId, setTokenId] = useState('');
  const [tokenPrice, setTokenPrice] = useState(0);
  const [balance, setBalance] = useState(0);


  useEffect(() => {
    initializeContract();
  });
  

  async function initializeContract() {
    try {
      // Connect to the Ethereum network
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      await provider.send('eth_requestAccounts', []);
      
      // Get the signer
      const signer = provider.getSigner();

      // Create an instance of the ZillennialMemeopolis contract
      const contractAddress = 'CONTRACT_ADDRESS'; // Replace with the actual contract address
      const zillennialMemeopolisContract = new ethers.Contract(contractAddress, ZillennialMemeopolisABI, signer);

      // Set the contract instance
      setContract(zillennialMemeopolisContract);

      // Get the token price
      const price = await zillennialMemeopolisContract.getTokenPrice(tokenId);
      setTokenPrice(price);

      // Get the contract balance
      const contractBalance = await provider.getBalance(contractAddress);
      setBalance(ethers.utils.formatEther(contractBalance));
    } catch (error) {
      console.error('Error initializing contract:', error);
    }
  }

  async function handleMintNFT() {
    try {
      // Mint a new NFT
      const recipient = 'RECIPIENT_ADDRESS'; // Replace with the actual recipient address
      const tokenURI = 'TOKEN_URI'; // Replace with the actual token URI
      const metadataURI = 'METADATA_URI'; // Replace with the actual metadata URI
      await contract.mintNFT(recipient, tokenURI, metadataURI);

      // Refresh the contract balance
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const contractBalance = await provider.getBalance(contract.address);
      setBalance(ethers.utils.formatEther(contractBalance));
    } catch (error) {
      console.error('Error minting NFT:', error);
    }
  }

  return (
    <div>
      <h1>Zillennial Memeopolis</h1>
      <p>Token ID: {tokenId}</p>
      <p>Token Price: {tokenPrice} ETH</p>
      <p>Contract Balance: {balance} ETH</p>
      <button onClick={handleMintNFT}>Mint NFT</button>
    </div>
  );
}

export default App;
