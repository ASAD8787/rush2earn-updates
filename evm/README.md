# Rush Token (Base Mainnet)

This package deploys an ERC-20 token named `Rush` (`RUSH`) to Base mainnet.

## 1) Install

```bash
cd evm
npm install
```

## 2) Configure environment

```bash
cp .env.example .env
```

Set:
- `BASE_MAINNET_RPC_URL` (Base RPC endpoint)
- `DEPLOYER_PRIVATE_KEY` (wallet that will deploy)
- `TOKEN_OWNER` (address that receives initial supply)
- `INITIAL_SUPPLY` (whole tokens, 18 decimals)
- `BASESCAN_API_KEY` (optional, for verification)

## 3) Compile

```bash
npm run compile
```

## 4) Deploy to Base mainnet

```bash
npm run deploy:base
```

## 5) Verify on Basescan

Use the command printed by the deploy script, for example:

```bash
npx hardhat verify --network base <TOKEN_ADDRESS> <TOKEN_OWNER> <INITIAL_SUPPLY_WEI>
```

## Contract details

- Name: `Rush`
- Symbol: `RUSH`
- Decimals: `18`
- Supply model: fixed initial supply minted in constructor
