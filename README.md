# Truffle-Hardhat-Template

### Author: Hephyrius

A template repo that I use for quickly starting new solidity projects.

Using hardhat for development and truffle for deployment.

### Install packages

```
yarn
```

### Setting up env variables

create a .env and fill values or use the .env.template and rename to .env

```
ACC_KEY = ""
RPC_LINK = "https://bsc-dataseed.binance.org/"
NETWORK_ID = 56
GAS_PRICE = 5000000000
```

## Test contracts

```
npx hardhat test
```

## Deploy to mainnet

```
truffle migrate --network live
```
