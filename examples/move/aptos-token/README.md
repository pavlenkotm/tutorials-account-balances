# Simple Token (Move on Aptos)

A fungible token implementation in Move language for the Aptos blockchain, demonstrating resource-oriented programming.

## Features

- ✅ Standard fungible token functionality
- ✅ Minting with admin controls
- ✅ Token burning capability
- ✅ Transfer functionality
- ✅ Event emission for all operations
- ✅ View functions for querying state
- ✅ Built-in tests
- ✅ Resource safety guarantees

## About Move & Aptos

### Move Language
Move is a resource-oriented programming language originally developed by Facebook for Diem:

- **Resource Safety**: Assets cannot be copied or accidentally lost
- **First-class Resources**: Digital assets are first-class citizens
- **Formal Verification**: Easier to prove contract correctness
- **Module System**: Clean separation of concerns
- **No Reentrancy**: By design, prevents reentrancy attacks

### Aptos Blockchain
Aptos is a Layer 1 blockchain built with Move:

- **High Performance**: 160,000+ TPS theoretical capacity
- **Parallel Execution**: Block-STM parallel execution engine
- **Low Latency**: Sub-second finality
- **Move VM**: Secure execution environment
- **Upgradeable Contracts**: Built-in upgrade mechanisms

## Tech Stack

- **Move**: Resource-oriented smart contract language
- **Aptos Framework**: Standard library and coin framework
- **Aptos CLI**: Development and deployment tools

## Project Structure

```
aptos-token/
├── sources/
│   └── simple_token.move    # Token implementation
├── Move.toml                 # Package configuration
└── README.md                 # Documentation
```

## Setup

### Install Aptos CLI

```bash
# macOS / Linux
curl -fsSL "https://aptos.dev/scripts/install_cli.py" | python3

# Or using Homebrew (macOS)
brew install aptos
```

### Initialize Aptos Account

```bash
# Initialize new account
aptos init

# Fund account on devnet
aptos account fund-with-faucet --account default
```

## Build & Test

```bash
# Compile the module
aptos move compile

# Run tests
aptos move test

# Run tests with coverage
aptos move test --coverage

# Publish to devnet
aptos move publish --named-addresses aptos_token=default
```

## Usage

### Initialize Token

```bash
aptos move run \
  --function-id 'default::simple_token::initialize' \
  --args string:"Simple Token" string:"STK" u8:8
```

### Register to Receive Tokens

```bash
aptos move run \
  --function-id 'default::simple_token::register'
```

### Mint Tokens

```bash
aptos move run \
  --function-id 'default::simple_token::mint' \
  --args address:0x123... u64:1000000000
```

### Transfer Tokens

```bash
aptos move run \
  --function-id 'default::simple_token::transfer' \
  --args address:0x456... u64:500000000
```

### Query Balance

```bash
aptos move view \
  --function-id 'default::simple_token::balance_of' \
  --args address:0x123...
```

## Module Structure

### Resources

```move
// Token type marker
struct SimpleToken has key {}

// Admin capabilities
struct Capabilities has key {
    mint_cap: MintCapability<SimpleToken>,
    burn_cap: BurnCapability<SimpleToken>,
    freeze_cap: FreezeCapability<SimpleToken>,
}

// Token metadata
struct TokenInfo has key {
    name: String,
    symbol: String,
    decimals: u8,
    total_supply: u64,
}
```

### Functions

- `initialize()`: Initialize the token (admin only, once)
- `register()`: Register account to receive tokens
- `mint()`: Mint new tokens (admin only)
- `burn()`: Burn tokens from caller
- `transfer()`: Transfer tokens to another account
- `balance_of()`: Query account balance (view)
- `total_supply()`: Query total supply (view)

### Events

```move
struct TokenMinted { recipient, amount, timestamp }
struct TokenBurned { account, amount, timestamp }
struct TokenTransferred { from, to, amount, timestamp }
```

## Security Features

### Move's Resource Model
- **No Copy**: Tokens cannot be duplicated
- **No Drop**: Tokens cannot be accidentally destroyed
- **Explicit Destruction**: Must explicitly burn to destroy
- **Transfer Safety**: Resources must be explicitly moved

### Additional Security
- Admin-only minting
- Account registration required
- Balance checks on transfers
- Total supply tracking
- Event emission for transparency

## Testing

The module includes comprehensive tests:

```move
#[test(admin = @aptos_token)]
fun test_initialize(admin: &signer)

#[test(admin = @aptos_token, user = @0x123)]
fun test_mint_and_transfer(admin: &signer, user: &signer)
```

Run tests:
```bash
aptos move test --filter simple_token
```

## Comparison: Move vs Solidity

| Feature | Move | Solidity |
|---------|------|----------|
| Asset Model | First-class resources | Value types |
| Reentrancy | Not possible by design | Needs guards |
| Formal Verification | Built-in support | External tools |
| Integer Overflow | Checked by default | Needs SafeMath/0.8+ |
| Asset Loss | Prevented by type system | Manual checks needed |
| Learning Curve | Moderate | Moderate |

## Why Use Move?

1. **Resource Safety**: Impossible to lose or duplicate assets
2. **Formal Verification**: Easier to prove correctness
3. **Clean Design**: No reentrancy or overflow issues
4. **Performance**: Optimized for blockchain execution
5. **Future-Proof**: Designed specifically for digital assets

## Resources

- [Move Language Book](https://move-language.github.io/move/)
- [Aptos Documentation](https://aptos.dev/)
- [Move Tutorial](https://github.com/aptos-labs/aptos-core/tree/main/aptos-move/move-examples)
- [Aptos TypeScript SDK](https://github.com/aptos-labs/aptos-ts-sdk)

## License

MIT
