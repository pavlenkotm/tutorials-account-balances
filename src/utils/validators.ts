// Validation functions for blockchain data

/**
 * Validate balance is non-negative
 * @param balance - Balance to validate
 */
export function validateBalance(balance: bigint): boolean {
    return balance >= BigInt(0);
}

/**
 * Validate block number is positive
 * @param blockNumber - Block number to validate
 */
export function validateBlockNumber(blockNumber: bigint): boolean {
    return blockNumber > BigInt(0);
}

/**
 * Validate timestamp is valid
 * @param timestamp - Timestamp to validate
 */
export function validateTimestamp(timestamp: bigint): boolean {
    const now = BigInt(Math.floor(Date.now() / 1000));
    // Timestamp should be less than current time and after genesis (2020)
    return timestamp > BigInt(1590000000) && timestamp <= now;
}

/**
 * Validate transfer amount
 * @param amount - Amount to validate
 */
export function validateTransferAmount(amount: bigint): boolean {
    return amount > BigInt(0);
}

/**
 * Validate account address format
 * @param address - Address to validate
 */
export function validateAccountAddress(address: string): boolean {
    if (!address || typeof address !== 'string') {
        return false;
    }

    // Polkadot addresses are typically 47-48 characters
    const length = address.length;
    if (length < 47 || length > 48) {
        return false;
    }

    // Should start with 1 (for Polkadot mainnet)
    return address.startsWith('1');
}

/**
 * Validate extrinsic hash format
 * @param hash - Hash to validate
 */
export function validateHash(hash: string): boolean {
    if (!hash || typeof hash !== 'string') {
        return false;
    }

    // Substrate hashes are 66 characters (0x + 64 hex chars)
    return hash.startsWith('0x') && hash.length === 66;
}
