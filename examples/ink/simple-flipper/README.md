# Simple Flipper (ink! on Polkadot/Substrate)

A production-ready flipper smart contract written in ink! for Polkadot parachains and Substrate-based blockchains.

## Features

- ✅ Flip boolean value (true/false)
- ✅ Track flip count per account
- ✅ Global flip counter
- ✅ Reset functionality (owner-only)
- ✅ Ownership transfer
- ✅ Event emission for all state changes
- ✅ Comprehensive error handling
- ✅ Full test coverage

## About ink! & Polkadot

### ink! Language
ink! is an embedded domain specific language (eDSL) for writing smart contracts in Rust:

- **Rust-based**: Leverage Rust's safety and performance
- **WebAssembly**: Compiles to Wasm for efficient execution
- **Type Safety**: Compile-time guarantees
- **Small Footprint**: Optimized binary sizes
- **Developer Friendly**: Familiar syntax for Rust developers
- **Upgradeable**: Support for proxy patterns

### Polkadot Ecosystem
Polkadot is a multi-chain platform enabling blockchain interoperability:

- **Shared Security**: All parachains share Polkadot's security
- **Cross-Chain**: Native interoperability via XCM
- **Substrate Framework**: Modular blockchain framework
- **Forkless Upgrades**: On-chain runtime upgrades
- **Nominated Proof-of-Stake**: Energy-efficient consensus

## Tech Stack

- **ink!**: v4.0+ (Smart contract framework)
- **Rust**: Systems programming language
- **cargo-contract**: Build and deployment tool
- **Substrate Contracts Pallet**: Smart contract execution environment

## Project Structure

```
simple-flipper/
├── lib.rs          # Smart contract implementation
├── Cargo.toml      # Rust dependencies
└── README.md       # Documentation
```

## Setup

### Prerequisites

```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Add WebAssembly target
rustup target add wasm32-unknown-unknown

# Install cargo-contract
cargo install cargo-contract --force

# Install substrate-contracts-node (for local testing)
cargo install contracts-node --git https://github.com/paritytech/substrate-contracts-node.git

# Verify installations
cargo-contract --version  # 3.0+
substrate-contracts-node --version
```

### Create Cargo.toml

```toml
[package]
name = "flipper"
version = "0.1.0"
edition = "2021"

[dependencies]
ink = { version = "4.0", default-features = false }
scale = { package = "parity-scale-codec", version = "3", default-features = false, features = ["derive"] }
scale-info = { version = "2", default-features = false, features = ["derive"], optional = true }

[dev-dependencies]
ink_e2e = "4.0"

[lib]
path = "lib.rs"

[features]
default = ["std"]
std = [
    "ink/std",
    "scale/std",
    "scale-info/std",
]
ink-as-dependency = []
```

## Build & Deploy

### Build Contract

```bash
# Build the contract
cargo contract build

# Check contract size
ls -lh target/ink/flipper.wasm

# Expected output: optimized Wasm binary
```

### Run Local Node

```bash
# Start local substrate-contracts-node
substrate-contracts-node --dev --tmp
```

### Deploy Contract

```bash
# Upload and instantiate
cargo contract instantiate \
  --constructor new \
  --args true \
  --suri //Alice \
  --execute

# Or use Polkadot.js Apps UI
# Navigate to Developer > Contracts > Upload & Deploy
```

## Usage

### Flip the Value

```bash
cargo contract call \
  --contract <CONTRACT_ADDRESS> \
  --message flip \
  --suri //Alice \
  --execute
```

### Get Current Value

```bash
cargo contract call \
  --contract <CONTRACT_ADDRESS> \
  --message get \
  --suri //Alice \
  --dry-run
```

### Get Flip Count

```bash
cargo contract call \
  --contract <CONTRACT_ADDRESS> \
  --message get_flip_count \
  --args <ACCOUNT_ADDRESS> \
  --suri //Alice \
  --dry-run
```

### Reset (Owner Only)

```bash
cargo contract call \
  --contract <CONTRACT_ADDRESS> \
  --message reset \
  --suri //Alice \
  --execute
```

## Contract Interface

### Storage

```rust
pub struct Flipper {
    value: bool,                          // Current value
    flip_counts: Mapping<AccountId, u32>, // Per-account flip counts
    total_flips: u64,                     // Total flips
    owner: AccountId,                     // Contract owner
}
```

### Functions

**Public Messages:**
- `flip()`: Toggle the boolean value
- `get()` → `bool`: View current value
- `get_flip_count(account)` → `u32`: View flip count for account
- `get_total_flips()` → `u64`: View total flips
- `get_owner()` → `AccountId`: View contract owner
- `reset()` → `Result<()>`: Reset to false (owner only)
- `transfer_ownership(new_owner)` → `Result<()>`: Transfer ownership

**Constructors:**
- `new(init_value: bool)`: Initialize with custom value
- `default()`: Initialize with false

### Events

```rust
Flipped {
    by: AccountId,        // Account that flipped
    new_value: bool,      // New value after flip
    flip_count: u32,      // Flip count for this account
}

Reset {
    by: AccountId,        // Account that reset (owner)
}
```

### Errors

```rust
pub enum Error {
    NotOwner,  // Caller is not the owner
}
```

## Testing

### Run Unit Tests

```bash
# Run all tests
cargo test

# Run with output
cargo test -- --nocapture

# Run specific test
cargo test flip_works
```

### Run Integration Tests

```bash
# E2E tests (requires running node)
cargo test --features e2e-tests
```

### Test Coverage

```bash
# Install tarpaulin
cargo install cargo-tarpaulin

# Generate coverage report
cargo tarpaulin --out Html --output-dir coverage
```

## Gas Costs

| Operation | Weight | Cost (on Rococo) |
|-----------|--------|------------------|
| Flip | ~150,000,000 | ~0.0015 ROC |
| Get | ~50,000,000 | Free (read-only) |
| Reset | ~100,000,000 | ~0.001 ROC |

*Actual costs vary by network*

## Comparison: ink! vs Solidity

| Feature | ink! | Solidity |
|---------|------|----------|
| Language | Rust (embedded) | Standalone |
| Target | WebAssembly | EVM bytecode |
| Type Safety | Strong (Rust) | Moderate |
| Memory Safety | Guaranteed | Manual |
| Tooling | cargo + rust-analyzer | Remix, Hardhat |
| Learning Curve | Moderate (Rust) | Easy |
| Gas Efficiency | High (Wasm) | Moderate |
| Upgradability | Proxy pattern | Proxy pattern |

## Security Features

- **Overflow Protection**: Rust's checked arithmetic by default
- **Memory Safety**: Rust prevents buffer overflows and null pointers
- **Type Safety**: Strong typing prevents many bugs at compile time
- **Access Control**: Owner-only functions with error handling
- **Event Logging**: Transparent state changes
- **Testing**: Comprehensive unit and integration tests

## Advanced Features

### Cross-Contract Calls

```rust
#[ink(message)]
pub fn call_other_contract(&mut self, contract: AccountId) {
    let result: bool = ink::env::call::build_call::<Environment>()
        .call(contract)
        .exec_input(ink::env::call::ExecutionInput::new(
            ink::env::call::Selector::new([0x12, 0x34, 0x56, 0x78])
        ))
        .returns::<bool>()
        .invoke();
}
```

### Upgradeable Pattern

```rust
#[ink(message)]
pub fn set_code(&mut self, code_hash: [u8; 32]) -> Result<()> {
    ensure_owner()?;
    ink::env::set_code_hash(&code_hash)
        .unwrap_or_else(|err| panic!("Failed to set code hash: {:?}", err));
    Ok(())
}
```

## Deployment Networks

### Testnet (Rococo Contracts)
```bash
cargo contract instantiate \
  --url wss://rococo-contracts-rpc.polkadot.io \
  --constructor new \
  --args true \
  --suri "your seed phrase" \
  --execute
```

### Parachain (e.g., Astar)
```bash
cargo contract instantiate \
  --url wss://astar.api.onfinality.io/public-ws \
  --constructor new \
  --args true \
  --suri "your seed phrase" \
  --execute
```

## Development Tools

### cargo-contract Commands
```bash
cargo contract new <name>        # Create new contract
cargo contract build             # Compile contract
cargo contract test              # Run tests
cargo contract instantiate       # Deploy contract
cargo contract call              # Interact with contract
cargo contract upload            # Upload code only
```

### Polkadot.js Integration

```typescript
import { ApiPromise, WsProvider } from '@polkadot/api';
import { ContractPromise } from '@polkadot/api-contract';

const wsProvider = new WsProvider('ws://localhost:9944');
const api = await ApiPromise.create({ provider: wsProvider });

const contract = new ContractPromise(api, abi, contractAddress);

// Call flip
await contract.tx.flip().signAndSend(alice);

// Read value
const { result } = await contract.query.get(alice.address);
console.log(result.toHuman());
```

## Resources

- [ink! Documentation](https://use.ink/)
- [Substrate Documentation](https://docs.substrate.io/)
- [Polkadot Wiki](https://wiki.polkadot.network/)
- [ink! Examples](https://github.com/paritytech/ink-examples)
- [Substrate Contracts Workshop](https://docs.substrate.io/tutorials/smart-contracts/)

## Why Use ink! on Polkadot?

1. **Interoperability**: Cross-chain messaging (XCM)
2. **Shared Security**: Benefit from Polkadot's validator set
3. **Rust Ecosystem**: Access to Rust's powerful tooling
4. **Wasm Performance**: Efficient execution
5. **Upgradeable**: Forkless runtime upgrades
6. **Developer Experience**: Familiar Rust syntax

## License

MIT
