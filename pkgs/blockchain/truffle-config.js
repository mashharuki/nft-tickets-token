require('dotenv').config();
const HDWalletProvider = require('@truffle/hdwallet-provider');

const { 
  MNEMONIC, 
  PROJECT_ID 
} = process.env;


module.exports = {

  networks: {
    
  },
  // Set default mocha options here, use special reporters, etc.
  mocha: {
  },
  compilers: {
    solc: {
      version: "0.8.20",      
      // docker: true,        
        settings: {          
          optimizer: {
            enabled: false,
            runs: 200
          },
      //  evmVersion: "byzantium"
       }
    }
  },
};
