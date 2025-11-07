#!/usr/bin/env python3
"""
Web3 Wallet Manager
A comprehensive Python utility for Ethereum wallet operations
"""

import json
import os
from typing import Dict, Optional, Tuple
from decimal import Decimal

from web3 import Web3
from web3.middleware import geth_poa_middleware
from eth_account import Account
from eth_account.signers.local import LocalAccount
from eth_typing import ChecksumAddress


class WalletManager:
    """
    Comprehensive wallet management for Ethereum
    """

    def __init__(self, rpc_url: str, chain_id: int = 1):
        """
        Initialize wallet manager

        Args:
            rpc_url: Ethereum node RPC URL
            chain_id: Chain ID (1=mainnet, 11155111=sepolia, etc.)
        """
        self.w3 = Web3(Web3.HTTPProvider(rpc_url))

        # Add PoA middleware for testnets like Sepolia
        if chain_id != 1:
            self.w3.middleware_onion.inject(geth_poa_middleware, layer=0)

        self.chain_id = chain_id

        if not self.w3.is_connected():
            raise ConnectionError(f"Failed to connect to {rpc_url}")

        print(f"✅ Connected to Ethereum (Chain ID: {chain_id})")

    def create_account(self) -> Tuple[str, str]:
        """
        Create a new Ethereum account

        Returns:
            Tuple of (address, private_key)
        """
        account: LocalAccount = Account.create()
        return account.address, account.key.hex()

    def load_account(self, private_key: str) -> LocalAccount:
        """
        Load an account from private key

        Args:
            private_key: Private key hex string

        Returns:
            LocalAccount object
        """
        return Account.from_key(private_key)

    def get_balance(self, address: str) -> Decimal:
        """
        Get ETH balance of an address

        Args:
            address: Ethereum address

        Returns:
            Balance in ETH
        """
        checksum_address = Web3.to_checksum_address(address)
        balance_wei = self.w3.eth.get_balance(checksum_address)
        return Decimal(self.w3.from_wei(balance_wei, 'ether'))

    def send_transaction(
        self,
        from_account: LocalAccount,
        to_address: str,
        amount_eth: str,
        gas_limit: int = 21000,
        max_priority_fee: Optional[int] = None,
        max_fee: Optional[int] = None,
    ) -> Dict:
        """
        Send ETH transaction (EIP-1559)

        Args:
            from_account: Sender account
            to_address: Recipient address
            amount_eth: Amount in ETH
            gas_limit: Gas limit
            max_priority_fee: Max priority fee per gas (gwei)
            max_fee: Max fee per gas (gwei)

        Returns:
            Transaction receipt
        """
        to_checksum = Web3.to_checksum_address(to_address)
        amount_wei = self.w3.to_wei(Decimal(amount_eth), 'ether')

        # Get current gas prices if not provided
        if max_priority_fee is None:
            max_priority_fee = self.w3.eth.max_priority_fee
        else:
            max_priority_fee = self.w3.to_wei(max_priority_fee, 'gwei')

        if max_fee is None:
            base_fee = self.w3.eth.get_block('latest')['baseFeePerGas']
            max_fee = base_fee * 2 + max_priority_fee
        else:
            max_fee = self.w3.to_wei(max_fee, 'gwei')

        # Build transaction
        transaction = {
            'from': from_account.address,
            'to': to_checksum,
            'value': amount_wei,
            'gas': gas_limit,
            'maxFeePerGas': max_fee,
            'maxPriorityFeePerGas': max_priority_fee,
            'nonce': self.w3.eth.get_transaction_count(from_account.address),
            'chainId': self.chain_id,
        }

        # Sign and send
        signed_txn = from_account.sign_transaction(transaction)
        tx_hash = self.w3.eth.send_raw_transaction(signed_txn.rawTransaction)

        print(f"📤 Transaction sent: {tx_hash.hex()}")
        print("⏳ Waiting for confirmation...")

        # Wait for receipt
        receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)

        if receipt['status'] == 1:
            print(f"✅ Transaction confirmed in block {receipt['blockNumber']}")
        else:
            print(f"❌ Transaction failed")

        return dict(receipt)

    def sign_message(self, account: LocalAccount, message: str) -> str:
        """
        Sign a message with an account

        Args:
            account: Account to sign with
            message: Message to sign

        Returns:
            Signature hex string
        """
        message_hash = self.w3.keccak(text=message)
        signed = account.signHash(message_hash)
        return signed.signature.hex()

    def verify_signature(
        self, message: str, signature: str, expected_address: str
    ) -> bool:
        """
        Verify a message signature

        Args:
            message: Original message
            signature: Signature to verify
            expected_address: Expected signer address

        Returns:
            True if signature is valid
        """
        message_hash = self.w3.keccak(text=message)
        recovered_address = Account.recover_message_hash(
            message_hash, signature=signature
        )
        return recovered_address.lower() == expected_address.lower()

    def get_transaction(self, tx_hash: str) -> Dict:
        """
        Get transaction details

        Args:
            tx_hash: Transaction hash

        Returns:
            Transaction details
        """
        return dict(self.w3.eth.get_transaction(tx_hash))

    def get_transaction_receipt(self, tx_hash: str) -> Dict:
        """
        Get transaction receipt

        Args:
            tx_hash: Transaction hash

        Returns:
            Transaction receipt
        """
        return dict(self.w3.eth.get_transaction_receipt(tx_hash))

    def estimate_gas(
        self, from_address: str, to_address: str, amount_eth: str
    ) -> int:
        """
        Estimate gas for a transaction

        Args:
            from_address: Sender address
            to_address: Recipient address
            amount_eth: Amount in ETH

        Returns:
            Estimated gas
        """
        from_checksum = Web3.to_checksum_address(from_address)
        to_checksum = Web3.to_checksum_address(to_address)
        amount_wei = self.w3.to_wei(Decimal(amount_eth), 'ether')

        return self.w3.eth.estimate_gas({
            'from': from_checksum,
            'to': to_checksum,
            'value': amount_wei,
        })

    def get_gas_price(self) -> Dict[str, int]:
        """
        Get current gas prices

        Returns:
            Dict with base_fee, max_priority_fee, and max_fee (in gwei)
        """
        base_fee = self.w3.eth.get_block('latest')['baseFeePerGas']
        max_priority_fee = self.w3.eth.max_priority_fee

        return {
            'base_fee_gwei': self.w3.from_wei(base_fee, 'gwei'),
            'max_priority_fee_gwei': self.w3.from_wei(max_priority_fee, 'gwei'),
            'max_fee_gwei': self.w3.from_wei(
                base_fee * 2 + max_priority_fee, 'gwei'
            ),
        }

    def get_block(self, block_number: str = 'latest') -> Dict:
        """
        Get block information

        Args:
            block_number: Block number or 'latest'

        Returns:
            Block details
        """
        return dict(self.w3.eth.get_block(block_number))


def main():
    """Example usage"""
    import sys

    # Configuration
    RPC_URL = os.getenv('ETH_RPC_URL', 'https://eth-sepolia.public.blastapi.io')
    CHAIN_ID = 11155111  # Sepolia

    # Initialize wallet manager
    manager = WalletManager(RPC_URL, CHAIN_ID)

    # Example 1: Create new account
    print("\n🔑 Creating new account...")
    address, private_key = manager.create_account()
    print(f"Address: {address}")
    print(f"Private Key: {private_key}")
    print("⚠️  NEVER share your private key!")

    # Example 2: Check balance
    print(f"\n💰 Checking balance...")
    balance = manager.get_balance(address)
    print(f"Balance: {balance} ETH")

    # Example 3: Get gas prices
    print(f"\n⛽ Current gas prices:")
    gas_prices = manager.get_gas_price()
    for key, value in gas_prices.items():
        print(f"  {key}: {value}")

    # Example 4: Get latest block
    print(f"\n📦 Latest block:")
    block = manager.get_block('latest')
    print(f"  Number: {block['number']}")
    print(f"  Hash: {block['hash'].hex()}")
    print(f"  Transactions: {len(block['transactions'])}")

    # Example 5: Sign message
    print(f"\n✍️  Signing message...")
    account = manager.load_account(private_key)
    message = "Hello, Web3!"
    signature = manager.sign_message(account, message)
    print(f"Message: {message}")
    print(f"Signature: {signature}")

    # Verify signature
    is_valid = manager.verify_signature(message, signature, address)
    print(f"Signature valid: {is_valid}")


if __name__ == "__main__":
    main()
