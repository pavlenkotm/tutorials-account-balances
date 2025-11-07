# Simple ERC-20 Token

A production-ready ERC-20 token implementation using OpenZeppelin contracts.

## Features

- ✅ Standard ERC-20 functionality (transfer, approve, transferFrom)
- ✅ Minting capability (owner only)
- ✅ Token burning
- ✅ Max supply cap (1 billion tokens)
- ✅ Ownable pattern for access control
- ✅ Comprehensive events logging

## Tech Stack

- **Solidity**: ^0.8.20
- **Hardhat**: Development environment
- **OpenZeppelin**: Battle-tested smart contract library
- **Ethers.js**: Ethereum library for deployment and testing

## Setup

```bash
npm install
```

## Compile

```bash
npm run compile
```

## Test

```bash
npm run test
```

## Deploy

### Local Network

```bash
# Terminal 1: Start local node
npm run node

# Terminal 2: Deploy
npm run deploy:local
```

### Testnet (Sepolia)

```bash
# Create .env file with:
# SEPOLIA_RPC_URL=your_rpc_url
# PRIVATE_KEY=your_private_key
# ETHERSCAN_API_KEY=your_api_key

npm run deploy:sepolia
```

## Contract Details

- **Token Name**: SimpleToken (configurable)
- **Symbol**: STK (configurable)
- **Decimals**: 18
- **Max Supply**: 1,000,000,000 tokens
- **Initial Supply**: Configurable at deployment

## Security Features

- Uses OpenZeppelin's audited contracts
- Max supply enforcement
- Owner-only minting
- Standard ERC-20 security patterns

## License

MIT
