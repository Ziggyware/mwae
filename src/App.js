import React, { useEffect, useState } from 'react';
import { Alchemy } from 'alchemy-sdk';

const alchemyAPIKey = 'YOUR_ALCHEMY_API_KEY';
const contractAddress = 'YOUR_CONTRACT_ADDRESS';

const App = () => {
  const [latestBlock, setLatestBlock] = useState(null);

  useEffect(() => {
    const alchemy = new Alchemy({ apiKey: alchemyAPIKey });

    const fetchLatestBlock = async () => {
      const blockNumber = await alchemy.core.getBlockNumber();
      setLatestBlock(blockNumber);
    };

    fetchLatestBlock();
  }, []);

  return (
    <div>
      <h1>Latest Block Number: {latestBlock}</h1>
    </div>
  );
};

export default App;
