require('dotenv').config();

const HDWalletProvider = require('truffle-hdwallet-provider');
const privateKey = process.env.privateKey;
const infuraKey = process.env.infuraKey
module.exports = {
  api_keys: {
    etherscan: process.env.bscKey
  },
  networks: {    
    rinkeby: {
      provider: function () {
        let privateKeys = [privateKey];
        return new HDWalletProvider(privateKeys, "https://rinkeby.infura.io/v3/" + infuraKey)
      },
      network_id: 4, // eslint-disable-line camelcase
      gas: 5500000, // Ropsten has a lower block limit than mainnet
      confirmations: 2, // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 200, // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true, // Skip dry run before migrations? (default: false for public nets )
    },    
  },
  compilers: {
    solc: {
      version: "^0.8.2",
      settings: {
        optimizer: {
          enabled: true, // Default: false
          runs: 200     // Default: 200
        },        
      }
    }
  },
  plugins: [
    'truffle-plugin-verify'
  ]
};
