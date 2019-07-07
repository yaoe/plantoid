require("babel-polyfill");
require("babel-register")({
  "presets": ["es2015"],
  "plugins": ["syntax-async-functions","transform-regenerator"]
});

const HDWalletProvider = require("truffle-hdwallet-provider-privkey");
const privKeys = ["D1E32164D27D0DABE6C48DC504EA25590A29FC62F5AE8746CF2FD7EF85CDD9B9"]; // private keys
var mnemonic = "twelve bacon solar behave web protect modify average evidence light banner name";


module.exports = {
  networks: {
    live: {
      network_id: 1,
      from: "0xdf2C0B1b3091EdFf1EbA111Ca9b338A260BbFD58",
      gas: 5500000,           // Default gas to send per transaction
      gasPrice: 20000000000,  // 2 gwei (default: 20 gwei)
      confirmations:8,       // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 200,     // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: false,        // Skip dry run before migrations? (default: false for public nets )
      provider: function() {
        return new HDWalletProvider(privKeys, "https://mainnet.infura.io/v3/af8ca76816644d44a908b6cb3d1bf690")
      }
    },
    ropsten: {
      network_id: 3,
      gas: 5500000,           // Default gas to send per transaction
      gasPrice: 2000000000,  // 2 gwei (default: 20 gwei)
      confirmations: 1,       // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 200,     // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true,        // Skip dry run before migrations? (default: false for public nets )
      provider: function() {
        return new HDWalletProvider(privKeys, "https://ropsten.infura.io/v3/3e0e337a9e144b08b56d2b1b35f3c90b")
      }
    },
    rinkeby: {
      network_id: 4,
      host: "localhost",
      port: 8545,
      gas: 4543760
    },
    kovan: {
      network_id: 42,
      gas: 5500000,           // Default gas to send per transaction
      gasPrice: 2000000000,  // 2 gwei (default: 20 gwei)
      confirmations: 1,       // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 200,     // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true,        // Skip dry run before migrations? (default: false for public nets )
      provider: function() {
        return new HDWalletProvider(mnemonic, "https://kovan.infura.io/v3/af8ca76816644d44a908b6cb3d1bf690")
      }
    },
    development: {
      network_id: "*",
      host: "localhost",
      port: 8545,
      gas: 4543760,
      skipDryRun: false
    },
  },
  solc: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  },
  compilers: {
    solc: {
         version: "0.4.25",    // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
      optimizer: {
        enabled: true,
        runs: 200
      }
      }
  },
  rpc: {
    host: "localhost",
    port: 8545
  }
};
