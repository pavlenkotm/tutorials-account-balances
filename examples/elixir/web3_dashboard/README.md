# 🧪 Elixir Web3 Dashboard

A production-ready **Phoenix LiveView** application for real-time Ethereum blockchain monitoring. Built with Elixir's fault-tolerant OTP principles and Phoenix Framework's reactive capabilities.

## 🌟 Features

### Real-Time Blockchain Monitoring
- **Live Block Updates**: Automatic polling and real-time display of latest block numbers
- **Gas Price Tracking**: Current network gas prices in Gwei
- **Balance Checker**: Query any Ethereum address balance instantly
- **Watchlist**: Monitor multiple addresses with automatic balance updates

### Production-Ready Architecture
- **GenServer Pattern**: Robust process management with OTP supervision
- **Connection Pooling**: Efficient RPC connection handling
- **Retry Logic**: Exponential backoff with configurable retries
- **PubSub Broadcasting**: Real-time updates via Phoenix PubSub
- **Error Recovery**: Automatic reconnection and fault tolerance

### Modern UI/UX
- **Phoenix LiveView**: Real-time updates without JavaScript
- **Tailwind CSS**: Beautiful, responsive gradient design
- **Live Updates**: Zero-latency UI updates via WebSocket
- **Reactive Components**: Instant feedback on all interactions

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────┐
│              Phoenix LiveView (UI)                  │
│  - DashboardLive: Real-time dashboard component    │
└────────────────┬────────────────────────────────────┘
                 │
                 │ (PubSub)
                 │
┌────────────────┴────────────────────────────────────┐
│         Application Supervisor                      │
├─────────────────────────────────────────────────────┤
│  • EthereumClient (GenServer)                      │
│    - Connection pooling                             │
│    - Retry logic with exponential backoff          │
│    - RPC call management                            │
│                                                      │
│  • BlockchainListener (GenServer)                  │
│    - Block polling (12s interval)                   │
│    - Gas price monitoring                           │
│    - PubSub broadcasting                            │
│    - Error tracking and recovery                    │
└─────────────────────────────────────────────────────┘
                 │
                 │ (JSON-RPC)
                 ▼
        ┌──────────────────┐
        │  Ethereum Node   │
        │  (RPC Endpoint)  │
        └──────────────────┘
```

## 📋 Prerequisites

- **Elixir**: >= 1.14
- **Erlang/OTP**: >= 25
- **Phoenix Framework**: ~> 1.7
- **PostgreSQL**: >= 14 (optional, for data persistence)
- **Node.js**: >= 18 (for asset compilation)

## 🚀 Quick Start

### 1. Install Dependencies

```bash
cd examples/elixir/web3_dashboard

# Install Elixir dependencies
mix deps.get

# Install Node.js dependencies for assets
cd assets && npm install && cd ..

# Or use the setup alias
mix setup
```

### 2. Configure RPC Endpoint

Edit `config/dev.exs`:

```elixir
config :web3_dashboard,
  rpc_url: "https://eth.llamarpc.com"  # Or your preferred RPC endpoint
```

### 3. Start the Phoenix Server

```bash
mix phx.server
```

Visit [`localhost:4000`](http://localhost:4000) in your browser!

## 🔧 Configuration

### RPC Provider

Configure your Ethereum RPC endpoint in `config/config.exs`:

```elixir
config :web3_dashboard,
  rpc_url: System.get_env("ETHEREUM_RPC_URL") || "https://eth.llamarpc.com"
```

### Polling Interval

Adjust blockchain polling frequency in `lib/web3_dashboard/blockchain_listener.ex`:

```elixir
@poll_interval 12_000  # 12 seconds (default Ethereum block time)
```

### Retry Configuration

Customize retry behavior in `lib/web3_dashboard/ethereum_client.ex`:

```elixir
@max_retries 3
@retry_delay 1000  # milliseconds
```

## 📊 Key Components

### EthereumClient (GenServer)

Manages JSON-RPC communication with retry logic:

```elixir
# Get account balance
{:ok, balance} = EthereumClient.get_balance("0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb")

# Get current block number
{:ok, block} = EthereumClient.get_block_number()

# Get gas price
{:ok, gas_price} = EthereumClient.get_gas_price()
```

### BlockchainListener (GenServer)

Polls blockchain and broadcasts updates:

```elixir
# Subscribe to updates in LiveView
BlockchainListener.subscribe()

# Receive updates
def handle_info({:blockchain_update, %{block_number: block, gas_price: gas}}, socket) do
  # Update UI
end
```

### DashboardLive (LiveView)

Real-time dashboard with reactive components:

- Balance checking with loading states
- Address watchlist with auto-refresh
- Live blockchain statistics
- Error handling and user feedback

## 🧪 Testing

```bash
# Run all tests
mix test

# Run with coverage
mix test --cover

# Run specific test file
mix test test/web3_dashboard/ethereum_client_test.exs
```

## 🏭 Production Deployment

### 1. Build Release

```bash
# Set production environment
export MIX_ENV=prod
export SECRET_KEY_BASE=$(mix phx.gen.secret)

# Compile assets
mix assets.deploy

# Build release
mix release
```

### 2. Run Release

```bash
_build/prod/rel/web3_dashboard/bin/web3_dashboard start
```

### 3. Environment Variables

```bash
# Required
ETHEREUM_RPC_URL=https://mainnet.infura.io/v3/YOUR_KEY
SECRET_KEY_BASE=your_secret_key

# Optional
PORT=4000
PHX_HOST=yourdomain.com
```

## 🔐 Security Best Practices

1. **Rate Limiting**: Use RPC providers with rate limiting (Infura, Alchemy)
2. **API Keys**: Store RPC API keys in environment variables
3. **HTTPS**: Always use SSL in production
4. **CORS**: Configure proper CORS policies
5. **Input Validation**: All user inputs are validated before RPC calls

## 🎯 Performance Features

- **Lazy Loading**: Components load data on-demand
- **Caching**: Implement ETS caching for frequent queries
- **Connection Pooling**: Efficient HTTP connection reuse
- **Async Processing**: Non-blocking RPC calls
- **PubSub Broadcasting**: Scalable real-time updates

## 🐛 Debugging

Enable debug logging:

```elixir
# config/dev.exs
config :logger, level: :debug
```

View LiveView debug information:

```elixir
# In IEx
require Logger
Logger.configure(level: :debug)
```

## 📚 Learning Resources

- [Phoenix Framework](https://www.phoenixframework.org/)
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/)
- [Elixir GenServer](https://hexdocs.pm/elixir/GenServer.html)
- [Ethereumex Library](https://github.com/mana-ethereum/ethereumex)

## 🤝 Contributing

Contributions welcome! Areas for improvement:

- WebSocket subscriptions for instant block updates
- Transaction history tracking
- Multi-chain support (Polygon, BSC, etc.)
- Historical balance charts
- Smart contract interaction

## 📄 License

MIT License - see LICENSE file for details

## 🌐 Related Examples

- **TypeScript**: React wallet with Wagmi
- **Python**: Web3.py utilities
- **Go**: ECDSA signature verification
- **Rust**: Solana programs with Anchor

---

**Built with Elixir 🧪 and Phoenix 🔥**
