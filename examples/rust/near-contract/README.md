# Counter Contract (Rust on NEAR Protocol)

A production-ready counter smart contract written in Rust for the NEAR Protocol blockchain.

## Features

- ✅ Increment/Decrement with overflow/underflow protection
- ✅ Increment by custom amount
- ✅ User activity tracking
- ✅ Action history (up to 1000 entries)
- ✅ Owner-only administrative functions
- ✅ Comprehensive statistics
- ✅ Event logging
- ✅ Full test coverage

## About Rust & NEAR Protocol

### Rust for Smart Contracts
Rust is ideal for blockchain development:

- **Memory Safety**: No null pointers or buffer overflows
- **Performance**: Zero-cost abstractions
- **Type Safety**: Strong compile-time guarantees
- **Concurrency**: Fearless concurrency
- **Ecosystem**: Rich crate ecosystem
- **WebAssembly**: Compiles to efficient Wasm

### NEAR Protocol
NEAR is a sharded, proof-of-stake blockchain:

- **Sharding**: Nightshade sharding for scalability
- **Fast Finality**: ~2 second block time
- **Low Fees**: Predictable, low transaction costs
- **Account Names**: Human-readable account IDs
- **Progressive Security**: Gradually increase security requirements
- **Storage Staking**: Pay for storage with staked tokens

## Tech Stack

- **Rust**: Systems programming language
- **near-sdk**: NEAR smart contract SDK
- **near-cli**: Command-line interface
- **cargo-near**: Build and deployment tool

## Project Structure

```
near-contract/
├── lib.rs         # Smart contract implementation
├── Cargo.toml     # Rust dependencies
└── README.md      # Documentation
```

## Setup

### Prerequisites

```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Add wasm32 target
rustup target add wasm32-unknown-unknown

# Install cargo-near
cargo install cargo-near

# Install NEAR CLI
npm install -g near-cli

# Verify installations
cargo-near --version
near --version
```

### Create Cargo.toml

```toml
[package]
name = "near-counter"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib", "rlib"]

[dependencies]
near-sdk = "5.0.0"

[dev-dependencies]
near-sdk = { version = "5.0.0", features = ["unit-testing"] }

[profile.release]
codegen-units = 1
opt-level = "z"
lto = true
debug = false
panic = "abort"
overflow-checks = true
```

## Build & Deploy

### Build Contract

```bash
# Build for release
cargo near build --release

# Check contract size
ls -lh target/wasm32-unknown-unknown/release/near_counter.wasm
```

### Create NEAR Account

```bash
# Login to NEAR
near login

# Create subaccount for contract
near create-account counter.YOUR_ACCOUNT.testnet \
  --masterAccount YOUR_ACCOUNT.testnet \
  --initialBalance 10
```

### Deploy Contract

```bash
# Deploy to testnet
near deploy \
  --accountId counter.YOUR_ACCOUNT.testnet \
  --wasmFile target/wasm32-unknown-unknown/release/near_counter.wasm

# Initialize contract
near call counter.YOUR_ACCOUNT.testnet new \
  '{"owner_id": "YOUR_ACCOUNT.testnet", "initial_value": 0}' \
  --accountId YOUR_ACCOUNT.testnet
```

## Usage

### Command Line (near-cli)

```bash
# Increment counter
near call counter.YOUR_ACCOUNT.testnet increment \
  --accountId YOUR_ACCOUNT.testnet

# Decrement counter
near call counter.YOUR_ACCOUNT.testnet decrement \
  --accountId YOUR_ACCOUNT.testnet

# Get counter value
near view counter.YOUR_ACCOUNT.testnet get_counter

# Increment by amount
near call counter.YOUR_ACCOUNT.testnet increment_by \
  '{"amount": 10}' \
  --accountId YOUR_ACCOUNT.testnet

# Get statistics
near view counter.YOUR_ACCOUNT.testnet get_stats

# Get history (last 10 entries)
near view counter.YOUR_ACCOUNT.testnet get_history '{"limit": 10}'

# Reset (owner only)
near call counter.YOUR_ACCOUNT.testnet reset \
  --accountId YOUR_ACCOUNT.testnet

# Set counter value (owner only)
near call counter.YOUR_ACCOUNT.testnet set_counter \
  '{"value": 100}' \
  --accountId YOUR_ACCOUNT.testnet
```

### JavaScript/TypeScript (near-api-js)

```typescript
import { connect, Contract, keyStores, WalletConnection } from 'near-api-js';

const config = {
  networkId: 'testnet',
  keyStore: new keyStores.BrowserLocalStorageKeyStore(),
  nodeUrl: 'https://rpc.testnet.near.org',
  walletUrl: 'https://wallet.testnet.near.org',
  helperUrl: 'https://helper.testnet.near.org',
};

const near = await connect(config);
const wallet = new WalletConnection(near);

const contract = new Contract(
  wallet.account(),
  'counter.YOUR_ACCOUNT.testnet',
  {
    viewMethods: ['get_counter', 'get_stats', 'get_history'],
    changeMethods: ['increment', 'decrement', 'reset'],
  }
);

// Increment counter
await contract.increment();

// Get counter value
const counter = await contract.get_counter();
console.log('Counter:', counter);

// Get statistics
const stats = await contract.get_stats();
console.log('Stats:', stats);
```

### React Integration

```typescript
import { useWallet } from '@near-wallet-selector/react';

function CounterApp() {
  const { selector, accountId } = useWallet();

  const increment = async () => {
    const wallet = await selector.wallet();
    await wallet.signAndSendTransaction({
      signerId: accountId,
      receiverId: 'counter.YOUR_ACCOUNT.testnet',
      actions: [
        {
          type: 'FunctionCall',
          params: {
            methodName: 'increment',
            args: {},
            gas: '30000000000000',
            deposit: '0',
          },
        },
      ],
    });
  };

  return (
    <button onClick={increment}>
      Increment Counter
    </button>
  );
}
```

## Contract Interface

### Types

```rust
pub struct ActionEntry {
    pub action: String,
    pub value: u64,
    pub timestamp: u64,
    pub account: AccountId,
}
```

### View Methods (Read-Only, Free)

- `get_counter() -> u64` - Get current counter value
- `get_owner() -> AccountId` - Get contract owner
- `get_total_increments() -> u64` - Get total increments
- `get_total_decrements() -> u64` - Get total decrements
- `get_user_count(account_id) -> u64` - Get user's action count
- `is_owner(account_id) -> bool` - Check if account is owner
- `get_history(limit) -> Vec<ActionEntry>` - Get recent history
- `get_history_length() -> u64` - Get total history entries
- `get_stats() -> JSON` - Get comprehensive statistics

### Change Methods (Modify State, Cost Gas)

- `increment() -> u64` - Increment counter by 1
- `decrement() -> u64` - Decrement counter by 1
- `increment_by(amount) -> u64` - Increment by amount
- `reset()` - Reset counter to 0 (owner only)
- `set_counter(value)` - Set counter value (owner only)
- `transfer_ownership(new_owner)` - Transfer ownership (owner only)
- `clear_history()` - Clear action history (owner only)

## Testing

### Unit Tests

```bash
# Run all tests
cargo test

# Run with output
cargo test -- --nocapture

# Run specific test
cargo test test_increment

# Test with coverage
cargo tarpaulin --out Html
```

### Integration Tests

Create `tests/integration.rs`:

```rust
use near_sdk::test_utils::VMContextBuilder;
use near_sdk::testing_env;

#[test]
fn test_integration() {
    let context = VMContextBuilder::new();
    testing_env!(context.build());

    let mut contract = Counter::default();

    // Test increment
    contract.increment();
    assert_eq!(contract.get_counter(), 1);

    // Test decrement
    contract.decrement();
    assert_eq!(contract.get_counter(), 0);
}
```

## Gas & Storage Costs

### Gas Costs (TGas = 10^12 gas)

| Operation | Gas (TGas) | Cost (NEAR) | USD |
|-----------|-----------|-------------|-----|
| Increment | ~3 | ~0.0003 | ~$0.0001 |
| Decrement | ~3 | ~0.0003 | ~$0.0001 |
| View Methods | 0 | Free | Free |
| Deploy | ~10 | ~0.001 | ~$0.0003 |

### Storage Costs

| Item | Size | Cost (NEAR) | USD |
|------|------|-------------|-----|
| 100KB Contract | 100KB | ~1 | ~$0.30 |
| Per Account Entry | ~100 bytes | ~0.001 | ~$0.0003 |
| Per History Entry | ~150 bytes | ~0.0015 | ~$0.00045 |

*1 NEAR ≈ $3.00 USD (varies)*

## Security Features

- **Memory Safety**: Rust prevents buffer overflows and null pointers
- **Overflow Protection**: Checked arithmetic with panics
- **Underflow Protection**: Explicit checks prevent negative values
- **Owner Access Control**: Owner-only functions
- **Type Safety**: Strong typing prevents type errors
- **Test Coverage**: Comprehensive unit tests

## Comparison: NEAR vs Other Chains

| Feature | NEAR | Solana | Ethereum |
|---------|------|--------|----------|
| Language | Rust | Rust | Solidity |
| TPS | 100,000+ | 65,000+ | ~15-30 |
| Finality | ~2s | ~0.4s | ~12s |
| Gas Cost | ~$0.0001 | <$0.001 | $2-50+ |
| Sharding | Yes | No | Future |
| Account Names | Human-readable | Base58 | Hex addresses |

## Advanced Features

### Cross-Contract Calls

```rust
use near_sdk::ext_contract;

#[ext_contract(ext_other)]
trait OtherContract {
    fn some_method(&self, arg: String) -> String;
}

#[near_bindgen]
impl Counter {
    pub fn call_other_contract(&self, contract_id: AccountId, arg: String) -> Promise {
        ext_other::ext(contract_id)
            .some_method(arg)
            .then(
                Self::ext(env::current_account_id())
                    .callback_handler()
            )
    }

    #[private]
    pub fn callback_handler(&self) -> String {
        // Handle callback
        "Success".to_string()
    }
}
```

### Payable Methods

```rust
#[payable]
pub fn deposit(&mut self) {
    let deposit = env::attached_deposit();
    env::log_str(&format!("Received {} yoctoNEAR", deposit));
}
```

### Storage Management

```rust
use near_sdk::json_types::U128;

#[near_bindgen]
impl Counter {
    #[payable]
    pub fn storage_deposit(&mut self, account_id: Option<AccountId>) {
        let account = account_id.unwrap_or_else(env::predecessor_account_id);
        let deposit = env::attached_deposit();
        // Store deposit for account's storage
    }

    pub fn storage_balance_of(&self, account_id: AccountId) -> U128 {
        // Return storage balance
        U128(0)
    }
}
```

## Development Tools

### cargo-near Commands
```bash
cargo near build          # Build contract
cargo near deploy         # Deploy contract
cargo near abi-schema     # Generate ABI
```

### near-cli Commands
```bash
near login               # Login to NEAR
near deploy              # Deploy contract
near call                # Call contract method
near view                # View contract state
near state               # View account state
near keys                # View access keys
near delete              # Delete account
```

## Mainnet Deployment

```bash
# Create mainnet account
near create-account counter.YOUR_ACCOUNT.near \
  --masterAccount YOUR_ACCOUNT.near \
  --initialBalance 50

# Deploy to mainnet
near deploy \
  --accountId counter.YOUR_ACCOUNT.near \
  --wasmFile target/wasm32-unknown-unknown/release/near_counter.wasm \
  --networkId mainnet

# Initialize
near call counter.YOUR_ACCOUNT.near new \
  '{"owner_id": "YOUR_ACCOUNT.near", "initial_value": 0}' \
  --accountId YOUR_ACCOUNT.near \
  --networkId mainnet
```

## Resources

- [NEAR Documentation](https://docs.near.org/)
- [near-sdk Rust](https://docs.near.org/sdk/rust/introduction)
- [NEAR Examples](https://github.com/near-examples)
- [NEAR University](https://www.near.university/)
- [NEAR Explorer](https://explorer.near.org/)

## Why Use Rust on NEAR?

1. **Sharding**: Built-in scalability via Nightshade
2. **Low Fees**: Predictable, affordable transactions
3. **Fast Finality**: ~2 second confirmation
4. **Developer Experience**: Rust's safety and tooling
5. **Human-Readable**: Named accounts (alice.near)
6. **Storage Staking**: Fair storage pricing model

## Upgradeable Contracts

NEAR contracts can be upgraded:

```bash
# Deploy new version
near deploy \
  --accountId counter.YOUR_ACCOUNT.testnet \
  --wasmFile target/wasm32-unknown-unknown/release/near_counter_v2.wasm

# State persists automatically!
```

## License

MIT
