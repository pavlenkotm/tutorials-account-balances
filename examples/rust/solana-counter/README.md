# Solana Counter Program (Rust + Anchor)

A production-ready counter program demonstrating Solana smart contract development using the Anchor framework.

## Features

- ✅ Initialize counter with PDA (Program Derived Address)
- ✅ Increment/Decrement operations with overflow/underflow protection
- ✅ Reset functionality
- ✅ Authority management and access control
- ✅ Event emission for all state changes
- ✅ Comprehensive error handling
- ✅ Secure PDA derivation with seeds

## Tech Stack

- **Rust**: Systems programming language
- **Anchor**: Solana development framework (v0.29.0)
- **Solana**: High-performance blockchain

## Why Solana + Anchor?

### Solana Benefits
- **High throughput**: 65,000+ TPS
- **Low fees**: Fraction of a cent per transaction
- **Fast finality**: ~400ms block time
- **Rust-based**: Memory safety without garbage collection

### Anchor Framework Benefits
- **Type safety**: Compile-time validation
- **Automatic serialization**: No manual borsh serialization
- **PDA helpers**: Simplified account derivation
- **Testing framework**: Built-in testing tools
- **IDL generation**: Automatic interface definitions

## Project Structure

```
solana-counter/
├── lib.rs          # Main program logic
├── Cargo.toml      # Rust dependencies
├── Anchor.toml     # Anchor configuration
└── README.md       # Documentation
```

## Setup

### Prerequisites

```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Install Solana CLI
sh -c "$(curl -sSfL https://release.solana.com/stable/install)"

# Install Anchor
cargo install --git https://github.com/coral-xyz/anchor avm --locked --force
avm install latest
avm use latest
```

### Build

```bash
# Build the program
anchor build

# Run tests
anchor test

# Deploy to localnet
anchor deploy
```

## Usage

### Initialize Counter

```typescript
const [counterPDA] = PublicKey.findProgramAddressSync(
  [Buffer.from("counter"), authority.publicKey.toBuffer()],
  program.programId
);

await program.methods
  .initialize()
  .accounts({
    counter: counterPDA,
    authority: authority.publicKey,
    systemProgram: SystemProgram.programId,
  })
  .rpc();
```

### Increment Counter

```typescript
await program.methods
  .increment()
  .accounts({
    counter: counterPDA,
    authority: authority.publicKey,
  })
  .rpc();
```

### Decrement Counter

```typescript
await program.methods
  .decrement()
  .accounts({
    counter: counterPDA,
    authority: authority.publicKey,
  })
  .rpc();
```

### Reset Counter

```typescript
await program.methods
  .reset()
  .accounts({
    counter: counterPDA,
    authority: authority.publicKey,
  })
  .rpc();
```

## Account Structure

```rust
pub struct Counter {
    pub count: u64,           // 8 bytes - current count
    pub authority: Pubkey,    // 32 bytes - authorized modifier
    pub bump: u8,             // 1 byte - PDA bump seed
}
```

## Security Features

- **PDA accounts**: Secure account derivation without private keys
- **Authority validation**: `has_one` constraint ensures only authorized users
- **Overflow protection**: Checked arithmetic prevents integer overflow
- **Underflow protection**: Prevents decrementing below zero
- **Custom errors**: Clear error messages for debugging

## Events

The program emits events for all state changes:

```rust
// Counter updated (increment/decrement)
CounterUpdated {
    counter: Pubkey,
    new_value: u64,
    timestamp: i64,
}

// Counter reset
CounterReset {
    counter: Pubkey,
    timestamp: i64,
}

// Authority updated
AuthorityUpdated {
    counter: Pubkey,
    old_authority: Pubkey,
    new_authority: Pubkey,
    timestamp: i64,
}
```

## Testing

```bash
# Run all tests
anchor test

# Run with logs
anchor test -- --nocapture

# Test specific file
anchor test tests/counter.test.ts
```

## Deployment

### Localnet
```bash
anchor deploy
```

### Devnet
```bash
anchor deploy --provider.cluster devnet
```

### Mainnet
```bash
anchor deploy --provider.cluster mainnet
```

## Program Accounts Cost

| Account | Size | Rent (SOL) |
|---------|------|------------|
| Counter | 49 bytes | ~0.00068 |

## Comparison: Solana vs Ethereum

| Feature | Solana | Ethereum |
|---------|--------|----------|
| TPS | 65,000+ | ~15-30 |
| Block Time | ~400ms | ~12s |
| Transaction Cost | <$0.001 | $2-50+ |
| Language | Rust | Solidity |
| Account Model | Account-based | UTXO-inspired |

## Resources

- [Anchor Documentation](https://www.anchor-lang.com/)
- [Solana Documentation](https://docs.solana.com/)
- [Solana Cookbook](https://solanacookbook.com/)

## License

MIT
