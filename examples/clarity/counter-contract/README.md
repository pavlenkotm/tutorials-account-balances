# Counter Contract (Clarity on Stacks / Bitcoin L2)

A production-ready counter smart contract written in Clarity for the Stacks blockchain, Bitcoin's Layer 2.

## Features

- ✅ Increment/Decrement counter with overflow/underflow protection
- ✅ Increment by custom amount
- ✅ User activity tracking (per-user action counts)
- ✅ Total increment/decrement statistics
- ✅ Owner-only administrative functions
- ✅ Event emission for all actions
- ✅ Read-only functions for querying state
- ✅ Decidable and type-safe code

## About Clarity & Stacks

### Clarity Language
Clarity is a decidable smart contract language for Bitcoin:

- **Decidable**: Program behavior can be determined from the code itself
- **No Compiler**: Interpreted language, what you see is what runs
- **No Reentrancy**: Language design prevents reentrancy attacks
- **Type Safety**: Strong typing with runtime checks
- **Lisp-based**: S-expression syntax (Scheme-like)
- **Post-Conditions**: Built-in verification of results

### Stacks Blockchain
Stacks brings smart contracts to Bitcoin:

- **Bitcoin Finality**: Transactions settle on Bitcoin
- **Proof of Transfer (PoX)**: Consensus mechanism using Bitcoin
- **Microblocks**: Fast transaction confirmation (~5 seconds)
- **Bitcoin DeFi**: DeFi applications secured by Bitcoin
- **STX Token**: Native token for gas and stacking
- **Stacking**: Earn BTC by locking STX

## Tech Stack

- **Clarity**: Decidable smart contract language
- **Stacks**: Bitcoin Layer 2 blockchain
- **Clarinet**: Development environment and testing framework
- **Stacks.js**: JavaScript SDK for interaction

## Project Structure

```
counter-contract/
├── counter.clar        # Smart contract implementation
├── Clarinet.toml       # Project configuration
├── tests/             # Contract tests
└── README.md          # Documentation
```

## Setup

### Prerequisites

```bash
# Install Clarinet (Clarity development tool)
curl -L https://github.com/hirosystems/clarinet/releases/latest/download/clarinet-linux-x64.tar.gz | tar xz
sudo mv clarinet /usr/local/bin/

# Or via Homebrew (macOS)
brew install clarinet

# Verify installation
clarinet --version
```

### Initialize Project

```bash
# Create new Clarinet project
clarinet new counter-project
cd counter-project

# Add the counter contract
# Copy counter.clar to contracts/counter.clar
```

### Create Clarinet.toml

```toml
[project]
name = "counter-contract"
description = "A simple counter contract on Stacks"
authors = ["Your Name"]
telemetry = false

[contracts.counter]
path = "contracts/counter.clar"

[repl.analysis]
passes = ["check_checker"]
```

## Build & Test

### Check Contract

```bash
# Check syntax and types
clarinet check

# Expected output: ✔ 0 error(s)
```

### Run Tests

```bash
# Run test suite
clarinet test

# Run tests with coverage
clarinet test --coverage

# Run specific test
clarinet test tests/counter_test.ts
```

### Interactive Console

```bash
# Start Clarinet console
clarinet console

# In console, call functions:
>> (contract-call? .counter increment)
>> (contract-call? .counter get-counter)
```

## Usage

### Deploy Contract

```bash
# Deploy to testnet
clarinet deploy --testnet

# Deploy to mainnet
clarinet deploy --mainnet
```

### Interact with Contract

Using Stacks CLI:

```bash
# Call increment
stx call-contract-func \
  ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.counter \
  increment \
  --testnet

# Call decrement
stx call-contract-func \
  ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.counter \
  decrement \
  --testnet

# Read counter value
stx call-read-only-contract-func \
  ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.counter \
  get-counter \
  --testnet
```

Using Stacks.js:

```typescript
import {
  makeContractCall,
  callReadOnlyFunction,
  standardPrincipalCV
} from '@stacks/transactions';
import { StacksTestnet } from '@stacks/network';

const network = new StacksTestnet();

// Increment counter
const txOptions = {
  contractAddress: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
  contractName: 'counter',
  functionName: 'increment',
  functionArgs: [],
  network,
  senderKey: privateKey,
};

const tx = await makeContractCall(txOptions);

// Read counter
const result = await callReadOnlyFunction({
  contractAddress: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
  contractName: 'counter',
  functionName: 'get-counter',
  functionArgs: [],
  network,
  senderAddress: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
});
```

## Contract Interface

### Data Variables

```clarity
counter          ;; Current counter value (uint)
total-increments ;; Total number of increments
total-decrements ;; Total number of decrements
```

### Data Maps

```clarity
user-counts       ;; principal → uint (action count per user)
user-last-action  ;; principal → uint (last action block height)
```

### Public Functions

- `(increment)` → `(response uint uint)`: Increment counter by 1
- `(decrement)` → `(response uint uint)`: Decrement counter by 1
- `(increment-by (amount uint))` → `(response uint uint)`: Increment by amount
- `(reset)` → `(response bool uint)`: Reset counter to 0 (owner only)
- `(set-counter (value uint))` → `(response uint uint)`: Set counter value (owner only)

### Read-Only Functions

- `(get-counter)` → `(response uint never)`: Get current counter value
- `(get-total-increments)` → `(response uint never)`: Get total increments
- `(get-total-decrements)` → `(response uint never)`: Get total decrements
- `(get-user-count (user principal))` → `(response uint never)`: Get user's action count
- `(get-user-last-action (user principal))` → `(response uint never)`: Get user's last action block
- `(get-owner)` → `(response principal never)`: Get contract owner
- `(is-owner)` → `(response bool never)`: Check if caller is owner

### Error Codes

```clarity
err-owner-only (u100)   ;; Only owner can perform this action
err-underflow (u101)    ;; Counter cannot be negative
err-overflow (u102)     ;; Counter overflow prevented
```

## Events

All functions emit events via `print`:

```clarity
;; Increment event
{
  event: "increment",
  user: tx-sender,
  new-value: <uint>,
  block: block-height
}

;; Decrement event
{
  event: "decrement",
  user: tx-sender,
  new-value: <uint>,
  block: block-height
}

;; Reset event
{
  event: "reset",
  user: tx-sender,
  block: block-height
}
```

## Testing

Create `tests/counter_test.ts`:

```typescript
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can increment counter",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;

    let block = chain.mineBlock([
      Tx.contractCall('counter', 'increment', [], deployer.address)
    ]);

    assertEquals(block.receipts.length, 1);
    assertEquals(block.receipts[0].result, '(ok u1)');

    // Check counter value
    let call = chain.callReadOnlyFn('counter', 'get-counter', [], deployer.address);
    call.result.expectOk().expectUint(1);
  },
});

Clarinet.test({
  name: "Can decrement counter",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;

    let block = chain.mineBlock([
      Tx.contractCall('counter', 'increment', [], deployer.address),
      Tx.contractCall('counter', 'decrement', [], deployer.address)
    ]);

    assertEquals(block.receipts[1].result, '(ok u0)');
  },
});

Clarinet.test({
  name: "Cannot decrement below zero",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;

    let block = chain.mineBlock([
      Tx.contractCall('counter', 'decrement', [], deployer.address)
    ]);

    assertEquals(block.receipts[0].result, '(err u101)');
  },
});

Clarinet.test({
  name: "Only owner can reset",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;

    let block = chain.mineBlock([
      Tx.contractCall('counter', 'reset', [], wallet1.address)
    ]);

    assertEquals(block.receipts[0].result, '(err u100)');
  },
});
```

## Security Features

- **Decidability**: Contract behavior is predictable and verifiable
- **No Reentrancy**: Language design prevents reentrancy attacks
- **Overflow/Underflow Protection**: Explicit checks for arithmetic safety
- **Owner Access Control**: Administrative functions restricted to owner
- **Type Safety**: Strong typing prevents many common bugs
- **Immutable Deployment**: Contracts cannot be changed after deployment

## Gas Costs

| Operation | Cost (µSTX) | USD Equivalent |
|-----------|-------------|----------------|
| Increment | ~1,000 | ~$0.001 |
| Decrement | ~1,000 | ~$0.001 |
| Reset | ~1,200 | ~$0.0012 |
| Read Operations | Free | Free |

*Costs vary with network congestion*

## Comparison: Clarity vs Solidity

| Feature | Clarity | Solidity |
|---------|---------|----------|
| Decidability | Yes | No |
| Reentrancy | Impossible | Needs guards |
| Compilation | Interpreted | Compiled |
| Readability | S-expressions | C-like |
| Blockchain | Bitcoin L2 | Ethereum |
| Post-conditions | Native | External |
| Learning Curve | Moderate (Lisp) | Moderate |

## Why Use Clarity on Stacks?

1. **Bitcoin Security**: Transactions settle on Bitcoin
2. **Decidable**: No surprises in contract behavior
3. **Safe by Design**: Prevents entire classes of vulnerabilities
4. **Bitcoin DeFi**: Build DeFi apps on Bitcoin
5. **Earn BTC**: Stacking rewards in Bitcoin
6. **Microblocks**: Fast confirmations (~5 seconds)

## Stacking (Earn BTC)

Integrate stacking into your contract:

```clarity
(define-public (stack-stx (amount uint) (pox-addr (tuple (version (buff 1)) (hashbytes (buff 32)))))
  (contract-call? 'SP000000000000000000002Q6VF78.pox stack-stx amount pox-addr)
)
```

## Advanced Features

### Cross-Contract Calls

```clarity
(define-public (call-other-contract)
  (contract-call? .other-contract some-function u123)
)
```

### Traits (Interfaces)

```clarity
(define-trait counter-trait
  (
    (increment () (response uint uint))
    (get-counter () (response uint never))
  )
)
```

## Development Tools

### Clarinet Commands
```bash
clarinet new <project>       # Create new project
clarinet check              # Check contract syntax
clarinet test               # Run tests
clarinet console            # Interactive REPL
clarinet deploy             # Deploy contracts
clarinet integrate          # Integration testing
```

### Explorer Integration
- Testnet: https://explorer.hiro.so/?chain=testnet
- Mainnet: https://explorer.hiro.so/?chain=mainnet

## Resources

- [Clarity Language Reference](https://docs.stacks.co/clarity)
- [Clarinet Documentation](https://docs.hiro.so/clarinet)
- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Book](https://book.clarity-lang.org/)
- [Stacks.js Documentation](https://docs.hiro.so/stacks.js)

## License

MIT
