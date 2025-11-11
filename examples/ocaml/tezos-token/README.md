# 🐫 OCaml/CameLIGO Tezos Token Contract

A production-ready **FA2 (TZIP-12)** token contract written in **CameLIGO** for the Tezos blockchain. CameLIGO uses OCaml-like syntax, bringing functional programming elegance to smart contract development.

## 🌟 Features

### FA2 Standard Compliance
- **Multi-Token Support**: Handle fungible and non-fungible tokens in a single contract
- **Batch Operations**: Transfer multiple tokens in one transaction (gas optimization)
- **Operator Pattern**: Delegate transfer permissions to other addresses
- **Balance Queries**: Off-chain balance lookups via callbacks
- **Metadata Support**: TZIP-16 compliant metadata

### Functional Programming Excellence
- **Type Safety**: Strong static typing catches errors at compile time
- **Immutability**: Pure functional data transformations
- **Pattern Matching**: Exhaustive case analysis for correctness
- **Higher-Order Functions**: Map, fold, and filter for elegant logic
- **Zero Runtime Errors**: Compile-time guarantees via OCaml's type system

### Security Features
- **Access Control**: Admin-only minting and burning
- **Operator Validation**: Permission checks on every transfer
- **Balance Verification**: Insufficient balance protection
- **Owner Validation**: Only owners can approve operators
- **Gas Optimization**: Efficient big_map usage and zero-balance removal

## 🏗️ Architecture

```ocaml
Storage Structure:
├── ledger: big_map(address × token_id → balance)
├── operators: big_map(owner × (operator × token_id) → unit)
├── token_metadata: big_map(token_id → metadata)
├── admin: address
└── total_supply: big_map(token_id → nat)

Entry Points:
├── Transfer: transfer_item list
├── Balance_of: balance_request list × callback
├── Update_operators: update_operator list
├── Mint: address × token_id × amount (admin only)
└── Burn: address × token_id × amount (admin only)
```

## 📋 Prerequisites

- **LIGO Compiler**: >= 0.73.0
- **Tezos Client**: >= 16.0
- **Docker** (optional, for containerized builds)
- **Node.js**: >= 18 (for deployment scripts)

## 🚀 Quick Start

### 1. Install LIGO

```bash
# Using Docker
docker pull ligolang/ligo:stable

# Or install directly
curl https://gitlab.com/ligolang/ligo/-/raw/dev/scripts/installer.sh | bash
```

### 2. Compile Contract

```bash
cd examples/ocaml/tezos-token

# Compile to Michelson
ligo compile contract token.mligo > token.tz

# Compile with optimization
ligo compile contract token.mligo --output-file token.tz --michelson-format json
```

### 3. Generate Initial Storage

```bash
# Create initial storage in Michelson format
ligo compile storage token.mligo 'init_storage' --output-file storage.tz
```

### 4. Run Tests

```bash
# Run all unit tests
ligo run test test_token.mligo

# Run specific test
ligo run test test_token.mligo --entry-point test_simple_transfer

# With verbose output
ligo run test test_token.mligo --verbose
```

## 🔧 Contract Usage

### Transfer Tokens

```ocaml
(* Single transfer *)
let transfer_param = [{
  from_ = alice_address;
  txs = [{
    to_ = bob_address;
    token_id = 0n;
    amount = 100n;
  }];
}]

(* Batch transfer to multiple recipients *)
let batch_transfer = [{
  from_ = alice_address;
  txs = [
    { to_ = bob_address;   token_id = 0n; amount = 50n };
    { to_ = carol_address; token_id = 0n; amount = 30n };
  ];
}]
```

### Approve Operator

```ocaml
(* Alice approves Bob to manage her tokens *)
let operator_update = [Add_operator {
  owner = alice_address;
  operator = bob_address;
  token_id = 0n;
}]
```

### Query Balances

```ocaml
(* Request balances *)
let balance_requests = [
  { owner = alice_address; token_id = 0n };
  { owner = bob_address;   token_id = 0n };
]

(* Specify callback contract to receive responses *)
let balance_of_param = (balance_requests, callback_contract)
```

### Mint New Tokens (Admin Only)

```ocaml
(* Mint 1000 tokens of type 0 to Alice *)
let mint_param = (alice_address, 0n, 1000n)
```

### Burn Tokens (Admin Only)

```ocaml
(* Burn 500 tokens of type 0 from Alice *)
let burn_param = (alice_address, 0n, 500n)
```

## 🧪 Testing

### Unit Tests

The contract includes comprehensive unit tests:

```bash
# Run all tests
ligo run test test_token.mligo

# Expected output:
# ✓ Simple transfer succeeded
# ✓ Batch transfer succeeded
# ✓ Operator transfer succeeded
# ✓ Minting succeeded
# ✓ Burning succeeded
# ✓ Multi-token support succeeded
```

### Dry-Run Testing

```bash
# Simulate a transfer
ligo run dry-run token.mligo \
  'Transfer([{from_=("tz1..." : address); txs=[...]}])' \
  'storage_expression'
```

## 🌐 Deployment

### Deploy to Testnet (Ghostnet)

```bash
# Set up Tezos client
tezos-client --endpoint https://ghostnet.tezos.marigold.dev config update

# Import admin account
tezos-client import secret key admin unencrypted:edsk...

# Originate contract
tezos-client originate contract fa2_token \
  transferring 0 from admin \
  running token.tz \
  --init "$(cat storage.tz)" \
  --burn-cap 2 \
  --force
```

### Deploy to Mainnet

```bash
# Connect to mainnet
tezos-client --endpoint https://mainnet.tezos.marigold.dev config update

# Originate with verified storage
tezos-client originate contract fa2_token_mainnet \
  transferring 0 from admin \
  running token.tz \
  --init "$(cat storage.tz)" \
  --burn-cap 2
```

## 🔐 Security Considerations

### Access Control
- **Admin Functions**: Only admin can mint/burn tokens
- **Owner Permissions**: Only token owners can approve operators
- **Operator Validation**: All transfers validate operator permissions

### Best Practices
- **Balance Checks**: Insufficient balance errors prevent invalid transfers
- **Zero-Balance Optimization**: Removes ledger entries for zero balances (gas savings)
- **Immutable Patterns**: Pure functions prevent state inconsistencies
- **Explicit Failures**: All error conditions have descriptive messages

### Audit Checklist
- ✅ No reentrancy vulnerabilities (Tezos prevents this by design)
- ✅ Integer overflow protection (nat type is unbounded)
- ✅ Access control on privileged functions
- ✅ Input validation on all parameters
- ✅ Comprehensive error messages

## 📊 Gas Costs (Estimated)

| Operation | Gas Cost | Storage Cost |
|-----------|----------|--------------|
| Transfer (single) | ~1,500 | 0 |
| Transfer (batch × 5) | ~5,000 | 0 |
| Add Operator | ~1,200 | 67 bytes |
| Mint | ~2,000 | 65 bytes |
| Burn | ~1,800 | -65 bytes |

## 🎯 Advanced Features

### Custom Token Metadata

```ocaml
let token_metadata_map = Map.literal [
  ("name", 0x4d79546f6b656e);        (* "MyToken" in hex *)
  ("symbol", 0x4d544b);               (* "MTK" in hex *)
  ("decimals", 0x3138);               (* "18" in hex *)
]

let metadata = {
  token_id = 0n;
  token_info = token_metadata_map;
}
```

### NFT Support

```ocaml
(* Mint unique NFT *)
let mint_nft = Mint(owner_address, 1n, 1n)  (* token_id=1, amount=1 *)

(* NFT metadata with URI *)
let nft_metadata = Map.literal [
  ("name", 0x...);
  ("artifactUri", 0x...);  (* IPFS link *)
  ("displayUri", 0x...);
]
```

## 📚 Learning Resources

- [CameLIGO Documentation](https://ligolang.org/docs/language-basics/cameligo)
- [FA2 Standard (TZIP-12)](https://tzip.tezosagora.org/proposal/tzip-12/)
- [Tezos Smart Contract Best Practices](https://docs.tezos.com/architecture/smart-contracts)
- [OCaml Programming Guide](https://ocaml.org/docs/)

## 🤝 Contributing

Enhancements welcome:
- Gas optimization techniques
- Additional FA2 extensions (permissions, pausable)
- Integration with Tezos indexers
- DeFi composability examples

## 🔗 Related Examples

- **Haskell**: Cardano Plutus validators
- **Move**: Aptos resource-based tokens
- **Solidity**: Ethereum ERC-20/ERC-721
- **Rust**: Solana SPL tokens

## 📄 License

MIT License - see LICENSE file for details

---

**Built with CameLIGO 🐫 for Tezos ꜩ**
