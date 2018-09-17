require("babel-polyfill");
require("babel-register")({
  "presets": ["es2015"],
  "plugins": ["syntax-async-functions","transform-regenerator"]
});

var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "grid dress decorate umbrella sunset width park corn federal two start nasty";


module.exports = {
  networks: {
    live: {
      network_id: 1,
      host: "localhost",
      port: 8546,
      gas: 4543760
    },
    ropsten: {
      network_id: 3,
      gas: 5500000,           // Default gas to send per transaction
      gasPrice: 2000000000,  // 2 gwei (default: 20 gwei)
      confirmations: 1,       // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 200,     // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true,        // Skip dry run before migrations? (default: false for public nets )
      provider: function() {
        return new HDWalletProvider(mnemonic, "https://ropsten.infura.io/v3/af8ca76816644d44a908b6cb3d1bf690")
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
      host: "localhost",
      port: 8545,
      gas: 4543760
    },
    development: {
      network_id: "*",
      host: "localhost",
      port: 8545,
      gas: 4543760
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
         version: "0.4.24",    // Fetch exact version from solc-bin (default: truffle's version)
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
