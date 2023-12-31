require('dotenv').config();
require("@nomiclabs/hardhat-ethers");
const { API_URL, PRIVATE_KEY } = process.env;
module.exports = {
   solidity: "0.8.18",
   defaultNetwork: "polygon_mainnet",
   networks: {
      hardhat: {},
      polygon_mainnet: {
         url: API_URL,
         accounts: [`0x${PRIVATE_KEY}`]
      }
   },
}