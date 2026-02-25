require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const privateKey = process.env.DEPLOYER_PRIVATE_KEY || "";
const baseMainnetRpc = process.env.BASE_MAINNET_RPC_URL || "";

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: { enabled: true, runs: 200 },
    },
  },
  networks: {
    base: {
      url: baseMainnetRpc,
      chainId: 8453,
      accounts: privateKey ? [privateKey] : [],
    },
  },
  etherscan: {
    apiKey: {
      base: process.env.BASESCAN_API_KEY || "",
    },
  },
};
