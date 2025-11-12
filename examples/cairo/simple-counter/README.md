# Simple Counter (Cairo on StarkNet)

A production-ready counter smart contract written in Cairo for the StarkNet Layer 2 blockchain.

## Features

- ✅ Initialize counter with custom initial value
- ✅ Increment/Decrement operations with underflow protection
- ✅ Reset functionality (owner-only)
- ✅ Event emission for all state changes
- ✅ Owner access control
- ✅ Efficient storage using u128
- ✅ Cairo 2.0 syntax with modern patterns

## About Cairo & StarkNet

### Cairo Language
Cairo is a Turing-complete language for writing provable programs:

- **Zero-Knowledge Proofs**: Generate validity proofs for execution
- **STARK-based**: Uses STARK proofs for scalability
- **Type Safety**: Rust-inspired syntax with strong typing
- **Provable Computation**: Every execution can be verified
- **Gas Efficiency**: Optimized for proof generation costs

### StarkNet Blockchain
StarkNet is a permissionless Layer 2 ZK-Rollup on Ethereum:

- **High Scalability**: Bundled transactions with validity proofs
- **Low Fees**: Drastically reduced gas costs vs L1
- **Ethereum Security**: Inherits Ethereum's security
- **Native Account Abstraction**: Advanced account features
- **Censorship Resistant**: Decentralized sequencers

## Tech Stack

- **Cairo**: v2.0+ (Provable smart contract language)
- **StarkNet**: Layer 2 ZK-Rollup
- **Scarb**: Cairo package manager
- **Starkli**: Command-line tool for StarkNet

## Project Structure

```
simple-counter/
├── counter.cairo       # Smart contract implementation
├── Scarb.toml         # Package configuration
└── README.md          # Documentation
```

## Setup

### Prerequisites

```bash
# Install Scarb (Cairo package manager)
curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh

# Install Starkli (CLI tool)
curl https://get.starkli.sh | sh
starkliup

# Verify installations
scarb --version  # 2.0+
starkli --version
```

### Create Scarb.toml

```toml
[package]
name = "simple_counter"
version = "0.1.0"
cairo-version = "2.5.0"

[dependencies]
starknet = ">=2.5.0"

[[target.starknet-contract]]
sierra = true
```

## Build & Deploy

### Compile Contract

```bash
# Compile to Sierra (intermediate representation)
scarb build

# Declare contract class
starkli declare target/dev/simple_counter_SimpleCounter.contract_class.json \
  --compiler-version 2.5.0 \
  --account ~/.starkli-wallets/deployer/account.json \
  --keystore ~/.starkli-wallets/deployer/keystore.json
```

### Deploy Contract

```bash
# Deploy with initial value of 0
starkli deploy <CLASS_HASH> 0 \
  --account ~/.starkli-wallets/deployer/account.json \
  --keystore ~/.starkli-wallets/deployer/keystore.json
```

## Usage

### Get Counter Value

```bash
starkli call <CONTRACT_ADDRESS> get_counter
```

### Increment Counter

```bash
starkli invoke <CONTRACT_ADDRESS> increment \
  --account ~/.starkli-wallets/deployer/account.json \
  --keystore ~/.starkli-wallets/deployer/keystore.json
```

### Decrement Counter

```bash
starkli invoke <CONTRACT_ADDRESS> decrement \
  --account ~/.starkli-wallets/deployer/account.json \
  --keystore ~/.starkli-wallets/deployer/keystore.json
```

### Reset Counter (Owner Only)

```bash
starkli invoke <CONTRACT_ADDRESS> reset \
  --account ~/.starkli-wallets/deployer/account.json \
  --keystore ~/.starkli-wallets/deployer/keystore.json
```

## Contract Interface

### Storage

```cairo
struct Storage {
    counter: u128,        // Current counter value
    owner: ContractAddress,  // Contract owner
}
```

### Functions

- `get_counter()` → `u128`: View current counter value
- `increment()`: Increase counter by 1
- `decrement()`: Decrease counter by 1 (reverts if counter is 0)
- `reset()`: Reset counter to 0 (owner only)
- `get_owner()` → `ContractAddress`: View contract owner

### Events

```cairo
CounterIncremented {
    caller: ContractAddress,
    new_value: u128,
}

CounterDecremented {
    caller: ContractAddress,
    new_value: u128,
}

CounterReset {
    caller: ContractAddress,
}
```

## Security Features

- **Underflow Protection**: Prevents decrementing below zero
- **Owner Access Control**: Only owner can reset counter
- **Event Transparency**: All state changes emit events
- **Type Safety**: Cairo's type system prevents common bugs
- **Proof Verification**: All executions are provable

## Testing

Create `tests/test_counter.cairo`:

```cairo
#[cfg(test)]
mod tests {
    use super::SimpleCounter;

    #[test]
    fn test_increment() {
        let mut state = SimpleCounter::contract_state_for_testing();
        SimpleCounter::constructor(ref state, 0);

        SimpleCounter::increment(ref state);
        assert(SimpleCounter::get_counter(@state) == 1, 'Increment failed');
    }

    #[test]
    fn test_decrement() {
        let mut state = SimpleCounter::contract_state_for_testing();
        SimpleCounter::constructor(ref state, 5);

        SimpleCounter::decrement(ref state);
        assert(SimpleCounter::get_counter(@state) == 4, 'Decrement failed');
    }

    #[test]
    #[should_panic(expected: ('Counter cannot be negative',))]
    fn test_decrement_underflow() {
        let mut state = SimpleCounter::contract_state_for_testing();
        SimpleCounter::constructor(ref state, 0);

        SimpleCounter::decrement(ref state); // Should panic
    }
}
```

Run tests:
```bash
scarb test
```

## Gas Costs

| Operation | Steps | Cost (ETH on L1) |
|-----------|-------|------------------|
| Increment | ~2,500 | ~$0.001 |
| Decrement | ~2,500 | ~$0.001 |
| Reset | ~2,600 | ~$0.001 |

*Costs significantly lower than Ethereum L1*

## Comparison: StarkNet vs Other L2s

| Feature | StarkNet | Optimism | Arbitrum |
|---------|----------|----------|----------|
| Proof Type | STARK (ZK) | Fraud Proof | Fraud Proof |
| Finality | ~4 hours | ~7 days | ~7 days |
| Language | Cairo | Solidity | Solidity |
| TPS | 10,000+ | 2,000+ | 4,000+ |
| Gas Costs | Very Low | Low | Low |
| Account Abstraction | Native | Limited | Limited |

## Cairo 2.0 Features Used

- ✅ Modern syntax (no `%` for builtins)
- ✅ Improved type system
- ✅ `ref` keyword for mutable references
- ✅ `@` for snapshots (read-only access)
- ✅ Built-in event system
- ✅ Native error messages with `assert`

## Development Tools

### Scarb Commands
```bash
scarb build          # Compile contracts
scarb test           # Run tests
scarb fmt            # Format code
scarb clean          # Clean build artifacts
```

### Starkli Commands
```bash
starkli declare      # Declare contract class
starkli deploy       # Deploy contract instance
starkli call         # Call view functions
starkli invoke       # Execute state-changing functions
starkli account      # Manage accounts
```

## Resources

- [Cairo Book](https://book.cairo-lang.org/)
- [StarkNet Documentation](https://docs.starknet.io/)
- [Scarb Documentation](https://docs.swmansion.com/scarb/)
- [Starkli Documentation](https://book.starkli.rs/)
- [Cairo by Example](https://cairo-by-example.com/)

## Advanced Features

### Upgradeability
StarkNet supports contract upgrades:
```cairo
#[external(v0)]
fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
    // Only owner
    assert(get_caller_address() == self.owner.read(), 'Unauthorized');
    replace_class_syscall(new_class_hash).unwrap();
}
```

### Multi-Counter
Extend to manage multiple counters:
```cairo
#[storage]
struct Storage {
    counters: LegacyMap<felt252, u128>,
}
```

## Why Use Cairo on StarkNet?

1. **Scalability**: ZK-Rollup technology for massive scaling
2. **Security**: Validity proofs ensure correctness
3. **Low Costs**: Significantly cheaper than Ethereum L1
4. **Provable**: Generate mathematical proofs of execution
5. **Future-Proof**: Built for the ZK-STARK era

## License

MIT
