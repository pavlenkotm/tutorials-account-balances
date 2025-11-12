# Counter Module (Go + Cosmos SDK)

A production-ready counter module for Cosmos SDK blockchain applications.

## Features

- ✅ Increment/Decrement counter with underflow protection
- ✅ Increment by custom amount
- ✅ Reset and set counter functionality
- ✅ Event emission for all state changes
- ✅ Query endpoints for state inspection
- ✅ Message handlers for transactions
- ✅ IBC compatibility ready
- ✅ Module-based architecture

## About Go & Cosmos SDK

### Go for Blockchain
Go is ideal for building blockchain infrastructure:

- **Concurrency**: Goroutines for high-performance networking
- **Simplicity**: Clean, readable syntax
- **Standard Library**: Rich built-in functionality
- **Fast Compilation**: Quick development iteration
- **Static Typing**: Type safety at compile time
- **Cross-Platform**: Build for any OS

### Cosmos SDK
The Cosmos SDK is a framework for building sovereign blockchains:

- **Modular**: Compose your blockchain from modules
- **IBC**: Inter-Blockchain Communication protocol
- **Tendermint**: Byzantine Fault Tolerant consensus
- **Sovereignty**: Full control over your chain
- **Interoperability**: Connect to the Cosmos ecosystem
- **ABCI**: Application Blockchain Interface

## Tech Stack

- **Go**: Systems programming language
- **Cosmos SDK**: Blockchain application framework
- **Tendermint**: BFT consensus engine
- **ABCI**: Application interface
- **gRPC**: High-performance RPC framework

## Project Structure

```
cosmos-module/
├── keeper.go       # State management logic
├── types.go        # Type definitions
├── msg.go          # Message types
├── handler.go      # Message handlers
├── query.go        # Query handlers
└── README.md       # Documentation
```

## Setup

### Prerequisites

```bash
# Install Go 1.21+
wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Verify installation
go version
```

### Initialize Cosmos Chain

```bash
# Install Ignite CLI (formerly Starport)
curl https://get.ignite.com/cli! | bash

# Create new blockchain
ignite scaffold chain github.com/username/counterchain

cd counterchain

# Add counter module
ignite scaffold module counter

# Add message types
ignite scaffold message increment --module counter --response counter:uint
ignite scaffold message decrement --module counter --response counter:uint
ignite scaffold message increment-by amount:uint --module counter --response counter:uint

# Add queries
ignite scaffold query get-counter --module counter --response counter:uint
ignite scaffold query get-stats --module counter --response stats
```

### Create go.mod

```go
module github.com/username/counterchain

go 1.21

require (
    github.com/cosmos/cosmos-sdk v0.47.5
    github.com/cosmos/ibc-go/v7 v7.3.0
    github.com/tendermint/tendermint v0.37.2
    google.golang.org/grpc v1.58.3
)
```

## Build & Run

### Build the Chain

```bash
# Build binary
ignite chain build

# Initialize chain
counterchaind init mynode --chain-id counterchain

# Add keys
counterchaind keys add alice
counterchaind keys add bob

# Add genesis accounts
counterchaind add-genesis-account alice 100000000stake
counterchaind add-genesis-account bob 100000000stake

# Create genesis transaction
counterchaind gentx alice 1000000stake --chain-id counterchain

# Collect genesis transactions
counterchaind collect-gentxs
```

### Start the Chain

```bash
# Start node
counterchaind start

# Or use Ignite for development
ignite chain serve
```

## Usage

### Command Line (CLI)

```bash
# Increment counter
counterchaind tx counter increment \
  --from alice \
  --chain-id counterchain \
  --yes

# Decrement counter
counterchaind tx counter decrement \
  --from alice \
  --chain-id counterchain \
  --yes

# Increment by amount
counterchaind tx counter increment-by 10 \
  --from alice \
  --chain-id counterchain \
  --yes

# Query counter value
counterchaind query counter get-counter

# Query statistics
counterchaind query counter get-stats
```

### Go Client

```go
package main

import (
    "context"
    "fmt"

    "github.com/cosmos/cosmos-sdk/client"
    "github.com/cosmos/cosmos-sdk/client/flags"
    "github.com/cosmos/cosmos-sdk/client/tx"
    sdk "github.com/cosmos/cosmos-sdk/types"
    "github.com/username/counterchain/x/counter/types"
)

func main() {
    // Setup client context
    clientCtx := client.Context{}.
        WithCodec(encodingConfig.Marshaler).
        WithChainID("counterchain")

    // Create increment message
    msg := types.NewMsgIncrement(
        "cosmos1abc...", // sender address
    )

    // Build and broadcast transaction
    txBuilder := clientCtx.TxConfig.NewTxBuilder()
    txBuilder.SetMsgs(msg)
    txBuilder.SetGasLimit(200000)

    txBytes, err := clientCtx.TxConfig.TxEncoder()(txBuilder.GetTx())
    if err != nil {
        panic(err)
    }

    // Broadcast transaction
    res, err := clientCtx.BroadcastTx(txBytes)
    if err != nil {
        panic(err)
    }

    fmt.Printf("Transaction hash: %s\n", res.TxHash)
}
```

### REST API

```bash
# Get counter value
curl http://localhost:1317/counterchain/counter/counter

# Get statistics
curl http://localhost:1317/counterchain/counter/stats

# Submit transaction (requires signing)
curl -X POST http://localhost:1317/cosmos/tx/v1beta1/txs \
  -H "Content-Type: application/json" \
  -d '{
    "tx": {...},
    "mode": "BROADCAST_MODE_SYNC"
  }'
```

### gRPC

```go
import (
    "context"
    "google.golang.org/grpc"
    countertypes "github.com/username/counterchain/x/counter/types"
)

// Connect to gRPC endpoint
conn, err := grpc.Dial("localhost:9090", grpc.WithInsecure())
if err != nil {
    panic(err)
}
defer conn.Close()

// Create query client
queryClient := countertypes.NewQueryClient(conn)

// Query counter
resp, err := queryClient.GetCounter(context.Background(), &countertypes.QueryGetCounterRequest{})
if err != nil {
    panic(err)
}

fmt.Printf("Counter: %d\n", resp.Counter)
```

## Module Interface

### Keeper Methods

```go
type Keeper interface {
    GetCounter(ctx sdk.Context) uint64
    SetCounter(ctx sdk.Context, counter uint64)
    Increment(ctx sdk.Context) (uint64, error)
    Decrement(ctx sdk.Context) (uint64, error)
    IncrementBy(ctx sdk.Context, amount uint64) (uint64, error)
    Reset(ctx sdk.Context) error
    SetCounterValue(ctx sdk.Context, value uint64) error
    GetStats(ctx sdk.Context) Stats
}
```

### Message Types

```go
// MsgIncrement increments the counter by 1
type MsgIncrement struct {
    Creator string `protobuf:"bytes,1,opt,name=creator,proto3" json:"creator,omitempty"`
}

// MsgDecrement decrements the counter by 1
type MsgDecrement struct {
    Creator string `protobuf:"bytes,1,opt,name=creator,proto3" json:"creator,omitempty"`
}

// MsgIncrementBy increments the counter by amount
type MsgIncrementBy struct {
    Creator string `protobuf:"bytes,1,opt,name=creator,proto3" json:"creator,omitempty"`
    Amount  uint64 `protobuf:"varint,2,opt,name=amount,proto3" json:"amount,omitempty"`
}
```

### Query Types

```go
// QueryGetCounterRequest is the request for GetCounter
type QueryGetCounterRequest struct{}

// QueryGetCounterResponse is the response for GetCounter
type QueryGetCounterResponse struct {
    Counter uint64 `protobuf:"varint,1,opt,name=counter,proto3" json:"counter,omitempty"`
}

// QueryGetStatsRequest is the request for GetStats
type QueryGetStatsRequest struct{}

// QueryGetStatsResponse is the response for GetStats
type QueryGetStatsResponse struct {
    Stats Stats `protobuf:"bytes,1,opt,name=stats,proto3" json:"stats,omitempty"`
}
```

### Events

```go
// Events emitted by the module
const (
    EventTypeIncrement   = "increment_counter"
    EventTypeDecrement   = "decrement_counter"
    EventTypeIncrementBy = "increment_counter_by"
    EventTypeReset       = "reset_counter"
    EventTypeSet         = "set_counter"
)

// Event attributes
const (
    AttributeKeyCounter = "counter_value"
    AttributeKeyAmount  = "amount"
    AttributeKeyAction  = "action"
)
```

## Testing

### Unit Tests

Create `keeper_test.go`:

```go
package counter_test

import (
    "testing"

    "github.com/stretchr/testify/require"
    keepertest "github.com/username/counterchain/testutil/keeper"
    "github.com/username/counterchain/x/counter/keeper"
)

func TestIncrement(t *testing.T) {
    k, ctx := keepertest.CounterKeeper(t)

    // Initial value should be 0
    counter := k.GetCounter(ctx)
    require.Equal(t, uint64(0), counter)

    // Increment
    newCounter, err := k.Increment(ctx)
    require.NoError(t, err)
    require.Equal(t, uint64(1), newCounter)

    // Verify stored value
    counter = k.GetCounter(ctx)
    require.Equal(t, uint64(1), counter)
}

func TestDecrement(t *testing.T) {
    k, ctx := keepertest.CounterKeeper(t)

    // Set initial value
    k.SetCounter(ctx, 5)

    // Decrement
    newCounter, err := k.Decrement(ctx)
    require.NoError(t, err)
    require.Equal(t, uint64(4), newCounter)
}

func TestDecrementUnderflow(t *testing.T) {
    k, ctx := keepertest.CounterKeeper(t)

    // Try to decrement from 0
    _, err := k.Decrement(ctx)
    require.Error(t, err)
    require.Contains(t, err.Error(), "underflow")
}
```

Run tests:
```bash
go test ./x/counter/keeper/...
```

### Integration Tests

```bash
# Run all tests
go test ./...

# Run with coverage
go test -cover ./x/counter/...

# Generate coverage report
go test -coverprofile=coverage.out ./x/counter/...
go tool cover -html=coverage.out
```

## Gas & Fees

### Gas Costs

| Operation | Gas | Fee (at 0.025stake/gas) |
|-----------|-----|-------------------------|
| Increment | ~50,000 | ~1,250 stake |
| Decrement | ~50,000 | ~1,250 stake |
| Query | 0 | Free |

### Configure Gas Prices

```toml
# config/app.toml
minimum-gas-prices = "0.025stake"
```

## Security Features

- **Type Safety**: Go's strong typing prevents errors
- **Underflow Protection**: Explicit checks
- **Event Logging**: Transparent state changes
- **Access Control**: SDK's built-in auth module
- **State Isolation**: Module keeper pattern
- **Deterministic**: Reproducible execution

## IBC Integration

Make the module IBC-compatible:

```go
// Implement IBC callbacks
func (k Keeper) OnRecvPacket(
    ctx sdk.Context,
    packet channeltypes.Packet,
    relayer sdk.AccAddress,
) error {
    // Handle incoming IBC packets
    var data types.CounterPacketData
    if err := types.ModuleCdc.UnmarshalJSON(packet.GetData(), &data); err != nil {
        return err
    }

    // Process packet data
    k.Increment(ctx)

    return nil
}
```

## Governance Integration

Add governance proposals:

```go
import (
    govtypes "github.com/cosmos/cosmos-sdk/x/gov/types/v1beta1"
)

// ProposalHandler handles governance proposals
func ProposalHandler(k Keeper) govtypes.Handler {
    return func(ctx sdk.Context, content govtypes.Content) error {
        switch c := content.(type) {
        case *types.UpdateCounterProposal:
            return k.SetCounterValue(ctx, c.Value)
        default:
            return fmt.Errorf("unrecognized proposal content type")
        }
    }
}
```

## Comparison: Cosmos SDK vs Other Frameworks

| Feature | Cosmos SDK | Substrate | Tendermint Core |
|---------|-----------|-----------|----------------|
| Language | Go | Rust | Go |
| Modularity | High | High | Low |
| IBC | Native | Bridge | No |
| Consensus | Tendermint | BABE/GRANDPA | Built-in |
| Learning Curve | Moderate | Hard | Easy |
| Ecosystem | Large | Growing | Large |

## Advanced Features

### Custom Ante Handler

```go
// Custom transaction validation
func CustomAnteHandler(
    ak auth.AccountKeeper,
    bankKeeper bank.Keeper,
) sdk.AnteHandler {
    return func(
        ctx sdk.Context,
        tx sdk.Tx,
        simulate bool,
    ) (sdk.Context, error) {
        // Custom validation logic
        return ctx, nil
    }
}
```

### BeginBlocker/EndBlocker

```go
// Execute logic at block boundaries
func BeginBlocker(ctx sdk.Context, k keeper.Keeper) {
    // Logic to run at the beginning of each block
    k.Logger(ctx).Info("Block started", "height", ctx.BlockHeight())
}

func EndBlocker(ctx sdk.Context, k keeper.Keeper) {
    // Logic to run at the end of each block
    k.Logger(ctx).Info("Block ended", "height", ctx.BlockHeight())
}
```

## Development Tools

### Ignite CLI Commands
```bash
ignite scaffold chain <name>     # Create new chain
ignite scaffold module <name>    # Add module
ignite scaffold message <name>   # Add message
ignite scaffold query <name>     # Add query
ignite chain serve              # Start dev environment
ignite chain build              # Build chain binary
```

### Cosmos SDK CLI
```bash
<appd> start                    # Start node
<appd> tx                       # Submit transaction
<appd> query                    # Query state
<appd> keys                     # Manage keys
<appd> config                   # Configure CLI
```

## Resources

- [Cosmos SDK Documentation](https://docs.cosmos.network/)
- [Ignite CLI Documentation](https://docs.ignite.com/)
- [Tendermint Documentation](https://docs.tendermint.com/)
- [IBC Protocol](https://ibc.cosmos.network/)
- [Cosmos Developer Portal](https://tutorials.cosmos.network/)

## Why Use Cosmos SDK?

1. **Sovereignty**: Full control over your blockchain
2. **Interoperability**: IBC connects to 100+ chains
3. **Modularity**: Compose features from modules
4. **Proven**: Powers Cosmos Hub, Osmosis, and more
5. **Active Ecosystem**: Large developer community
6. **Go Language**: Fast development, great tooling

## Production Deployment

### Mainnet Checklist

- [ ] Audit smart contract logic
- [ ] Security review of keeper methods
- [ ] Test on testnet extensively
- [ ] Configure proper gas prices
- [ ] Set up monitoring and alerts
- [ ] Prepare genesis file
- [ ] Coordinate validator set
- [ ] Document upgrade procedures

### Monitoring

```bash
# Prometheus metrics
curl http://localhost:26660/metrics

# Node status
counterchaind status

# Query latest block
counterchaind query block
```

## License

MIT
