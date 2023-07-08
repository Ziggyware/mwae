import React, { useEffect, useState } from 'react';
import Web3 from 'web3';
import CombinedContract from './contracts/CombinedContract.json';

function App() {
  const [contract, setContract] = useState(null);
  const [data, setData] = useState('');

  useEffect(() => {
    const init = async () => {
      try {
        // Connect to the blockchain
        const web3 = new Web3(Web3.givenProvider || 'http://localhost:8545');
        const networkId = await web3.eth.net.getId();

        // Get the contract instance
        const deployedNetwork = CombinedContract.networks[networkId];
        const contractInstance = new web3.eth.Contract(
          CombinedContract.abi,
          deployedNetwork && deployedNetwork.address
        );

        setContract(contractInstance);
      } catch (error) {
        console.error('Error initializing contract:', error);
      }
    };

    init();
  }, []);

  const fetchData = async () => {
    try {
      // Call the contract function to fetch data
      const result = await contract.methods.getData().call();
      setData(result);
    } catch (error) {
      console.error('Error fetching data:', error);
    }
  };

  return (
    <div>
      <h1>Combined Contract Data</h1>
      <button onClick={fetchData}>Fetch Data</button>
      <p>Data: {data}</p>
    </div>
  );
}

export default App;
