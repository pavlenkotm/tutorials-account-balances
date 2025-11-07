# Simple NFT Collection (ERC-721)

A full-featured ERC-721 NFT collection with metadata storage, batch minting, and payment handling.

## Features

- ✅ Standard ERC-721 functionality
- ✅ URI storage for metadata (IPFS compatible)
- ✅ Public minting with configurable price
- ✅ Batch minting for airdrops (owner only)
- ✅ Max supply enforcement (10,000 NFTs)
- ✅ Enable/disable minting controls
- ✅ Automatic payment refunds for overpayment
- ✅ Owner withdrawal functionality
- ✅ Query all tokens owned by address

## Tech Stack

- **Solidity**: ^0.8.20
- **OpenZeppelin**: ERC721URIStorage, Ownable, Counters
- **Hardhat**: Development and testing
- **Ethers.js**: Deployment and interaction

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

## Usage

### Minting an NFT

```solidity
// Mint with payment
contract.mint(recipientAddress, "ipfs://QmX...metadata.json", { value: mintPrice });
```

### Batch Minting (Owner Only)

```solidity
// Airdrop multiple NFTs
address[] memory recipients = [address1, address2, address3];
string[] memory uris = ["ipfs://QmA...", "ipfs://QmB...", "ipfs://QmC..."];
contract.batchMint(recipients, uris);
```

### Configuration

```solidity
// Update mint price (owner only)
contract.setMintPrice(ethers.parseEther("0.02"));

// Disable minting (owner only)
contract.setMintingEnabled(false);

// Withdraw funds (owner only)
contract.withdraw();
```

## Contract Details

- **Max Supply**: 10,000 NFTs
- **Default Mint Price**: 0.01 ETH
- **Metadata**: IPFS-compatible URI storage
- **Token IDs**: Sequential starting from 1

## Metadata Format

NFT metadata should follow the OpenSea standard:

```json
{
  "name": "NFT Name #1",
  "description": "NFT Description",
  "image": "ipfs://QmImage...",
  "attributes": [
    {
      "trait_type": "Rarity",
      "value": "Rare"
    }
  ]
}
```

## Security

- Max supply enforcement prevents overselling
- Owner-only administrative functions
- Automatic refund for overpayment
- Uses audited OpenZeppelin contracts
- Reentrancy protection via OpenZeppelin

## License

MIT
