# Simple Counter DApp (Motoko on Internet Computer)

A production-ready counter application written in Motoko for the Internet Computer (DFINITY).

## Features

- ✅ Increment/Decrement counter with underflow protection
- ✅ Increment by custom amount
- ✅ User activity tracking with timestamps
- ✅ Action history (last 100 actions)
- ✅ Owner-only administrative functions
- ✅ Upgrade-safe storage (stable variables)
- ✅ Fast query functions (no state modification)
- ✅ Comprehensive statistics
- ✅ Result types for error handling

## About Motoko & Internet Computer

### Motoko Language
Motoko is a modern programming language designed specifically for the Internet Computer:

- **Actor-based**: Natural fit for the IC's canister model
- **Type Safety**: Strong static typing with type inference
- **Async/Await**: Built-in asynchronous programming
- **Upgrade Safety**: Stable variables persist across upgrades
- **WebAssembly**: Compiles to efficient Wasm
- **Familiar Syntax**: JavaScript/TypeScript-inspired syntax

### Internet Computer (IC)
The Internet Computer is a blockchain that runs at web speed:

- **Web Speed**: ~1 second finality
- **Reverse Gas**: Users don't pay for transactions
- **Unlimited Scalability**: Add more subnets for capacity
- **Direct HTTP**: Serve web content directly from blockchain
- **Chain-Key Crypto**: Advanced cryptography for interoperability
- **Cycles**: Predictable compute cost model

## Tech Stack

- **Motoko**: Actor-based smart contract language
- **dfx**: DFINITY command-line tool
- **Internet Computer**: Blockchain computer
- **Candid**: Interface description language

## Project Structure

```
simple-dapp/
├── main.mo         # Motoko canister code
├── dfx.json        # Project configuration
└── README.md       # Documentation
```

## Setup

### Prerequisites

```bash
# Install dfx (DFINITY SDK)
sh -ci "$(curl -fsSL https://internetcomputer.org/install.sh)"

# Verify installation
dfx --version  # 0.15+

# Start local replica (for testing)
dfx start --clean --background
```

### Create dfx.json

```json
{
  "canisters": {
    "counter": {
      "main": "main.mo",
      "type": "motoko"
    }
  },
  "defaults": {
    "build": {
      "args": "",
      "packtool": ""
    }
  },
  "output_env_file": ".env",
  "version": 1
}
```

## Build & Deploy

### Local Development

```bash
# Start local replica
dfx start --clean --background

# Deploy canister locally
dfx deploy counter

# Get canister ID
dfx canister id counter
```

### Mainnet Deployment

```bash
# Create canister on mainnet
dfx canister --network ic create counter

# Deploy to mainnet
dfx deploy --network ic counter

# Check canister status
dfx canister --network ic status counter
```

## Usage

### Command Line (dfx)

```bash
# Increment counter
dfx canister call counter increment

# Decrement counter
dfx canister call counter decrement

# Get counter value
dfx canister call counter getCounter

# Increment by amount
dfx canister call counter incrementBy '(5)'

# Get statistics
dfx canister call counter getStats

# Get user stats
dfx canister call counter getUserStats '(principal "xxxxx-xxxxx-xxxxx-xxxxx-xxx")'

# Reset (owner only)
dfx canister call counter reset

# Set counter value (owner only)
dfx canister call counter setCounter '(42)'
```

### JavaScript/TypeScript

```typescript
import { Actor, HttpAgent } from "@dfinity/agent";
import { idlFactory } from "./declarations/counter";

const agent = new HttpAgent({ host: "https://ic0.app" });
const canisterId = "rrkah-fqaaa-aaaaa-aaaaq-cai";

const counter = Actor.createActor(idlFactory, {
  agent,
  canisterId,
});

// Increment counter
await counter.increment();

// Get counter value
const value = await counter.getCounter();
console.log("Counter:", value);

// Get statistics
const stats = await counter.getStats();
console.log("Stats:", stats);
```

### React Integration

```typescript
import { useCanister } from "@ic-reactor/react";

function CounterApp() {
  const { actor, call, loading } = useCanister("counter");

  const increment = async () => {
    await call("increment");
  };

  const getCounter = async () => {
    const value = await call("getCounter");
    console.log("Counter:", value);
  };

  return (
    <div>
      <button onClick={increment} disabled={loading}>
        Increment
      </button>
      <button onClick={getCounter}>
        Get Counter
      </button>
    </div>
  );
}
```

## Canister Interface

### Types

```motoko
type UserStats = {
  actionCount: Nat;
  lastAction: Time;
};

type HistoryEntry = {
  action: Text;
  value: Nat;
  timestamp: Time;
  caller: Principal;
};

type Error = {
  #Unauthorized;
  #Underflow;
  #NotFound;
};
```

### Query Functions (Fast, Read-Only)

- `getCounter() : async Nat` - Get current counter value
- `getOwner() : async Principal` - Get canister owner
- `getTotalIncrements() : async Nat` - Get total increment count
- `getTotalDecrements() : async Nat` - Get total decrement count
- `getUserStats(Principal) : async ?UserStats` - Get user statistics
- `getHistory() : async [HistoryEntry]` - Get action history
- `isOwner(Principal) : async Bool` - Check if principal is owner
- `getStats() : async {...}` - Get comprehensive statistics

### Update Functions (Modify State)

- `increment() : async Nat` - Increment counter by 1
- `decrement() : async Result<Nat, Error>` - Decrement counter by 1
- `incrementBy(Nat) : async Nat` - Increment counter by amount
- `reset() : async Result<(), Error>` - Reset counter to 0 (owner only)
- `setCounter(Nat) : async Result<Nat, Error>` - Set counter value (owner only)
- `transferOwnership(Principal) : async Result<(), Error>` - Transfer ownership
- `clearHistory() : async Result<(), Error>` - Clear action history (owner only)

## Upgrade Safety

Motoko provides upgrade-safe storage with stable variables:

```motoko
stable var counter : Nat = 0;
stable var owner : Principal = ...;

system func preupgrade() {
  // Save state before upgrade
  userStatsEntries := Iter.toArray(userStats.entries());
};

system func postupgrade() {
  // Restore state after upgrade
  userStats := HashMap.fromIter(...);
};
```

### Upgrade Canister

```bash
# Local
dfx deploy counter --mode upgrade

# Mainnet
dfx deploy --network ic counter --mode upgrade
```

## Testing

Create `test.sh`:

```bash
#!/bin/bash

echo "Testing Counter Canister..."

# Deploy
dfx deploy counter

# Test increment
echo "Test 1: Increment"
dfx canister call counter increment
VALUE=$(dfx canister call counter getCounter | sed 's/[^0-9]//g')
if [ "$VALUE" == "1" ]; then
  echo "✓ Increment works"
else
  echo "✗ Increment failed"
fi

# Test decrement
echo "Test 2: Decrement"
dfx canister call counter decrement
VALUE=$(dfx canister call counter getCounter | sed 's/[^0-9]//g')
if [ "$VALUE" == "0" ]; then
  echo "✓ Decrement works"
else
  echo "✗ Decrement failed"
fi

# Test underflow protection
echo "Test 3: Underflow Protection"
RESULT=$(dfx canister call counter decrement)
if echo "$RESULT" | grep -q "Underflow"; then
  echo "✓ Underflow protection works"
else
  echo "✗ Underflow protection failed"
fi

echo "All tests completed!"
```

Run tests:
```bash
chmod +x test.sh
./test.sh
```

## Cycles & Cost Management

The Internet Computer uses "cycles" for compute:

```bash
# Check canister cycles balance
dfx canister --network ic status counter

# Top up cycles (mainnet)
dfx canister --network ic deposit-cycles 1000000000000 counter

# Monitor cycles consumption
dfx canister --network ic call counter __get_cycles_balance
```

### Cost Estimates

| Operation | Cycles | USD Equivalent |
|-----------|--------|----------------|
| Increment | ~1M | ~$0.0000013 |
| Decrement | ~1M | ~$0.0000013 |
| Query | ~0 | Free |
| Storage (1GB/month) | ~0.46T | ~$0.60 |

*1 Trillion cycles ≈ $1.30 USD*

## Security Features

- **Caller Authentication**: Automatic via `msg.caller`
- **Owner Access Control**: Owner-only functions
- **Underflow Protection**: Checked arithmetic
- **Type Safety**: Compile-time guarantees
- **Upgrade Safety**: Stable variables preserve state
- **Immutable History**: Transparent audit trail

## Comparison: Motoko vs Other Languages

| Feature | Motoko | Solidity | Rust |
|---------|--------|----------|------|
| Learning Curve | Easy | Moderate | Hard |
| Type Safety | Strong | Moderate | Strong |
| Async/Await | Native | No | Yes |
| Upgrade Safety | Built-in | Proxies | Manual |
| Blockchain | Internet Computer | Ethereum | Multi |
| Gas Model | Reverse gas | User pays | Varies |

## Advanced Features

### Inter-Canister Calls

```motoko
import OtherCanister "canister:other";

public func callOtherCanister() : async Nat {
  await OtherCanister.someFunction()
};
```

### HTTP Outcalls

```motoko
import IC "mo:base/ExperimentalInternetComputer";

public func fetchData() : async Text {
  let result = await IC.http_request({
    url = "https://api.example.com/data";
    max_response_bytes = ?1000;
    headers = [];
    body = null;
    method = #get;
    transform = null;
  });
  // Process result
};
```

### Timers

```motoko
import Timer "mo:base/Timer";

let timerId = Timer.recurringTimer(
  #seconds 60,
  func() : async () {
    // Execute every 60 seconds
    counter += 1;
  }
);
```

## Candid Interface

Candid is the interface description language for IC:

```candid
type Result = variant {
  Ok : nat;
  Err : Error;
};

type Error = variant {
  Unauthorized;
  Underflow;
  NotFound;
};

service : {
  increment : () -> (nat);
  decrement : () -> (Result);
  getCounter : () -> (nat) query;
  reset : () -> (Result);
}
```

## Development Tools

### dfx Commands
```bash
dfx new <project>       # Create new project
dfx deploy              # Deploy canisters
dfx canister call       # Call canister functions
dfx canister status     # Check canister status
dfx ledger balance      # Check ICP balance
dfx identity list       # List identities
```

### Vessel (Package Manager)
```bash
# Install vessel
sudo curl -fsSL https://github.com/dfinity/vessel/releases/latest/download/vessel-linux64 -o /usr/local/bin/vessel
sudo chmod +x /usr/local/bin/vessel

# Add dependencies
vessel install
```

## Resources

- [Motoko Documentation](https://internetcomputer.org/docs/current/motoko/main/motoko)
- [Internet Computer Documentation](https://internetcomputer.org/docs)
- [Motoko Playground](https://m7sm4-2iaaa-aaaab-qabra-cai.ic0.app/)
- [Motoko Base Library](https://internetcomputer.org/docs/current/motoko/main/base/)
- [DFINITY Examples](https://github.com/dfinity/examples)

## Why Use Motoko on Internet Computer?

1. **Web Speed**: 1-2 second finality
2. **Reverse Gas**: Users don't pay for gas
3. **Unlimited Scaling**: Subnet-based scalability
4. **Direct Web Serving**: No separate frontend hosting
5. **Easy Upgrades**: Stable variables for safe upgrades
6. **Modern Language**: Clean, type-safe syntax

## Frontend Integration

Serve frontend directly from canister:

```motoko
import Http "mo:base/Http";

public query func http_request(req : Http.Request) : async Http.Response {
  {
    status_code = 200;
    headers = [("Content-Type", "text/html")];
    body = Text.encodeUtf8("<html>...</html>");
  }
};
```

## License

MIT
