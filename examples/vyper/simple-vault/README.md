# Simple Vault (Vyper)

A secure vault contract written in Vyper for depositing and withdrawing ETH.

## Features

- ✅ ETH deposit and withdrawal functionality
- ✅ Individual balance tracking per user
- ✅ Minimum deposit enforcement
- ✅ Pausable mechanism for emergencies
- ✅ Owner-only administrative functions
- ✅ Emergency withdrawal capability
- ✅ Comprehensive event logging

## About Vyper

Vyper is a pythonic smart contract language for the Ethereum Virtual Machine (EVM):

- **Security-focused**: Eliminates many footguns present in Solidity
- **Simple syntax**: Python-like syntax, easy to read and audit
- **No inheritance**: Reduces complexity and attack surface
- **Built-in overflow protection**: Safe math by default

## Tech Stack

- **Vyper**: ^0.3.9
- **Ethereum**: EVM-compatible chains
- **Brownie/Hardhat**: Development frameworks (compatible with both)

## Setup

### Using Vyper directly

```bash
# Install Vyper
pip install vyper

# Compile
vyper Vault.vy
```

### Using Brownie

```bash
# Install Brownie
pip install eth-brownie

# Initialize project
brownie init

# Compile
brownie compile
```

## Contract Interface

### User Functions

```python
# Deposit ETH (payable)
vault.deposit(value=amount)

# Withdraw specific amount
vault.withdraw(amount)

# Withdraw all
vault.withdrawAll()

# Check balance
vault.getBalance(address)
```

### Admin Functions (Owner Only)

```python
# Set minimum deposit
vault.setMinDeposit(newAmount)

# Pause/unpause contract
vault.setPaused(True/False)

# Transfer ownership
vault.transferOwnership(newOwner)

# Emergency withdrawal
vault.emergencyWithdraw()
```

## Security Features

- Minimum deposit enforcement prevents dust attacks
- Pausable mechanism for emergency situations
- Owner-only administrative functions
- No reentrancy vulnerabilities (Vyper's design prevents this)
- Simple and auditable code structure

## Comparison: Vyper vs Solidity

| Feature | Vyper | Solidity |
|---------|-------|----------|
| Syntax | Python-like | JavaScript-like |
| Inheritance | ❌ No | ✅ Yes |
| Modifiers | ❌ No | ✅ Yes |
| Overflow Protection | ✅ Built-in | Requires SafeMath/^0.8.0 |
| Inline Assembly | Limited | Full support |
| Learning Curve | Easier | Steeper |

## Why Use Vyper?

1. **Security**: Simpler language = fewer vulnerabilities
2. **Auditability**: Python-like syntax is easier to read
3. **Safety**: Built-in protections against common exploits
4. **Explicitness**: No hidden behavior or complex inheritance

## Testing

```python
# Example test using Brownie
def test_deposit(accounts, vault):
    vault.deposit({"from": accounts[0], "value": "1 ether"})
    assert vault.getBalance(accounts[0]) == "1 ether"

def test_withdraw(accounts, vault):
    vault.deposit({"from": accounts[0], "value": "1 ether"})
    vault.withdraw(0.5e18, {"from": accounts[0]})
    assert vault.getBalance(accounts[0]) == "0.5 ether"
```

## License

MIT
