require('dotenv').config();

const HDWalletProvider = require("@truffle/hdwallet-provider");


module.exports = {

  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*",
      gas: 6000000
    },
    bsc_testnet: {
      provider: () => new HDWalletProvider(
        process.env.MNEMONIC_TESTNET,
        process.env.MORALIS_BSC_TESTNET_PROVIDER
      ),
      network_id: 97,
      confirmations: 1,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    rinkeby: {
      provider: () => new HDWalletProvider(
        process.env.MNEMONIC_TESTNET,
        process.env.MORALIS_RINKEBY_PROVIDER
      ),
      gas: 6700000,
      gasPrice : 10000000000,
      network_id: 4,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    bsc: {
      provider: () => new HDWalletProvider(
        process.env.MNEMONIC_MAINNET,
        process.env.MORALIS_BSC_MAINNET_PROVIDER
      ),
      network_id: 56,
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: true
    }
  },

  mocha: {
    reporter: 'eth-gas-reporter',
    reporterOptions: {
      coinmarketcap: 'f06d27d0-ee31-4039-9e15-ee0dc215a3c4',
      token: 'BNB',
      excludeContracts: ['Migrations'],
      currency: 'USD',
      gasPriceApi: 'https://api.bscscan.com/api?module=proxy&action=eth_gasPrice',
    }
    // reporter options: https://www.npmjs.com/package//eth-gas-reporter
  },

  compilers: {
    solc: {
      version: "^0.6.0",
      settings: {
       optimizer: {
         enabled: true,
         runs: 1000
       },
      }
    }
  },

  plugins: [
    'truffle-flatten'
  ]
};
