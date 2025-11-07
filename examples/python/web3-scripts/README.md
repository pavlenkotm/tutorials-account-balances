# Web3 Python Scripts

Comprehensive Python utilities for Ethereum blockchain operations using Web3.py.

## Features

- ✅ Wallet creation and management
- ✅ Balance checking
- ✅ Transaction sending (EIP-1559)
- ✅ Message signing and verification
- ✅ Gas price estimation
- ✅ Block and transaction queries
- ✅ Type-safe with type hints
- ✅ Comprehensive error handling

## Tech Stack

- **Python**: 3.8+
- **web3.py**: Official Ethereum Python library
- **eth-account**: Account management
- **eth-typing**: Type definitions

## Why Python for Web3?

### Advantages
- **Rapid Development**: Quick prototyping and scripting
- **Data Analysis**: Integration with pandas, numpy for analytics
- **Automation**: Easy task scheduling and automation
- **Scientific Computing**: ML/AI integration for predictions
- **Backend Services**: Build APIs with Flask/FastAPI

### Use Cases
- 📊 Blockchain data analysis
- 🤖 Trading bots and automation
- 🔍 Contract monitoring and alerts
- 📈 Portfolio tracking
- 🧪 Testing and development tools

## Setup

### Install Dependencies

```bash
pip install -r requirements.txt
```

Or using poetry:

```bash
poetry install
```

### Environment Variables

Create a `.env` file:

```bash
ETH_RPC_URL=https://eth-sepolia.public.blastapi.io
PRIVATE_KEY=your_private_key_here  # Optional for read-only operations
```

## Usage

### Basic Example

```python
from wallet_manager import WalletManager

# Initialize
manager = WalletManager(
    rpc_url="https://eth-sepolia.public.blastapi.io",
    chain_id=11155111  # Sepolia testnet
)

# Create new wallet
address, private_key = manager.create_account()
print(f"New wallet: {address}")

# Check balance
balance = manager.get_balance(address)
print(f"Balance: {balance} ETH")
```

### Send Transaction

```python
from wallet_manager import WalletManager

manager = WalletManager(rpc_url, chain_id)
account = manager.load_account(private_key)

# Send ETH (EIP-1559)
receipt = manager.send_transaction(
    from_account=account,
    to_address="0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
    amount_eth="0.01",
    gas_limit=21000,
)

print(f"Transaction hash: {receipt['transactionHash'].hex()}")
print(f"Status: {'Success' if receipt['status'] == 1 else 'Failed'}")
```

### Sign and Verify Message

```python
# Sign message
account = manager.load_account(private_key)
message = "Hello, Web3!"
signature = manager.sign_message(account, message)

# Verify signature
is_valid = manager.verify_signature(
    message=message,
    signature=signature,
    expected_address=account.address
)

print(f"Signature valid: {is_valid}")
```

### Get Gas Prices

```python
gas_prices = manager.get_gas_price()

print(f"Base Fee: {gas_prices['base_fee_gwei']} gwei")
print(f"Priority Fee: {gas_prices['max_priority_fee_gwei']} gwei")
print(f"Max Fee: {gas_prices['max_fee_gwei']} gwei")
```

### Query Blocks and Transactions

```python
# Get latest block
block = manager.get_block('latest')
print(f"Block #{block['number']}")
print(f"Transactions: {len(block['transactions'])}")

# Get transaction details
tx = manager.get_transaction(tx_hash)
print(f"From: {tx['from']}")
print(f"To: {tx['to']}")
print(f"Value: {manager.w3.from_wei(tx['value'], 'ether')} ETH")
```

## WalletManager Class

### Methods

| Method | Description |
|--------|-------------|
| `create_account()` | Generate new Ethereum account |
| `load_account(pk)` | Load account from private key |
| `get_balance(address)` | Get ETH balance |
| `send_transaction(...)` | Send ETH transaction |
| `sign_message(account, msg)` | Sign a message |
| `verify_signature(...)` | Verify message signature |
| `get_transaction(hash)` | Get transaction details |
| `get_transaction_receipt(hash)` | Get transaction receipt |
| `estimate_gas(...)` | Estimate gas for transaction |
| `get_gas_price()` | Get current gas prices |
| `get_block(number)` | Get block information |

## Running Examples

```bash
# Run the demo
python wallet_manager.py

# With custom RPC
ETH_RPC_URL=https://mainnet.infura.io/v3/YOUR_KEY python wallet_manager.py
```

## Advanced Usage

### Batch Operations

```python
# Check multiple balances
addresses = ["0x...", "0x...", "0x..."]
balances = [manager.get_balance(addr) for addr in addresses]

for addr, bal in zip(addresses, balances):
    print(f"{addr}: {bal} ETH")
```

### Gas Optimization

```python
# Estimate gas first
estimated_gas = manager.estimate_gas(
    from_address=account.address,
    to_address=recipient,
    amount_eth="0.1"
)

# Send with estimated gas
receipt = manager.send_transaction(
    from_account=account,
    to_address=recipient,
    amount_eth="0.1",
    gas_limit=estimated_gas
)
```

### Error Handling

```python
from web3.exceptions import TransactionNotFound, ContractLogicError

try:
    receipt = manager.send_transaction(...)
except ValueError as e:
    print(f"Invalid transaction: {e}")
except TransactionNotFound:
    print("Transaction not found")
except Exception as e:
    print(f"Error: {e}")
```

## Testing

```bash
# Install test dependencies
pip install pytest pytest-cov

# Run tests
pytest tests/

# With coverage
pytest --cov=wallet_manager tests/
```

## Common Use Cases

### 1. Portfolio Tracker

```python
wallets = {
    "Main Wallet": "0x...",
    "Trading Wallet": "0x...",
    "Savings": "0x..."
}

total = 0
for name, address in wallets.items():
    balance = manager.get_balance(address)
    print(f"{name}: {balance} ETH")
    total += balance

print(f"\nTotal: {total} ETH")
```

### 2. Transaction Monitor

```python
def monitor_address(address, callback):
    """Monitor an address for new transactions"""
    last_block = manager.w3.eth.block_number

    while True:
        current_block = manager.w3.eth.block_number

        for block_num in range(last_block + 1, current_block + 1):
            block = manager.get_block(block_num)

            for tx_hash in block['transactions']:
                tx = manager.get_transaction(tx_hash.hex())
                if tx['to'] == address or tx['from'] == address:
                    callback(tx)

        last_block = current_block
        time.sleep(15)  # Check every 15 seconds
```

### 3. Gas Price Alert

```python
def alert_low_gas(threshold_gwei=20):
    """Alert when gas prices are below threshold"""
    gas_prices = manager.get_gas_price()

    if gas_prices['base_fee_gwei'] < threshold_gwei:
        print(f"🔔 Low gas alert! {gas_prices['base_fee_gwei']} gwei")
        # Send notification, email, etc.
```

## Security Best Practices

1. **Never hardcode private keys**: Use environment variables
2. **Use .env files**: Keep secrets out of code
3. **Validate addresses**: Always use `Web3.to_checksum_address()`
4. **Test on testnets**: Use Sepolia/Goerli before mainnet
5. **Handle errors**: Proper try-except blocks
6. **Rate limiting**: Respect RPC provider limits
7. **Secure storage**: Encrypt private keys at rest

## Comparison: Python vs JavaScript/TypeScript

| Feature | Python (web3.py) | JS/TS (ethers.js) |
|---------|------------------|-------------------|
| Syntax | Clean, readable | Modern, async/await |
| Type Safety | Type hints (optional) | Native TypeScript |
| Data Analysis | ✅ Excellent (pandas) | ⚠️ Limited |
| Frontend | ❌ No | ✅ Yes |
| Backend | ✅ Excellent | ✅ Good |
| Scientific Computing | ✅ Excellent | ❌ No |
| Ecosystem | Mature | Larger |

## Resources

- [Web3.py Documentation](https://web3py.readthedocs.io/)
- [Ethereum Python Ecosystem](https://ethereum.org/en/developers/docs/programming-languages/python/)
- [eth-account Documentation](https://eth-account.readthedocs.io/)

## License

MIT
