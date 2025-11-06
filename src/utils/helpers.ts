// Helper functions for SubQuery indexer

/**
 * Format balance from BigInt to human-readable string
 * @param balance - Balance in smallest unit
 * @param decimals - Number of decimals (default 10 for DOT)
 */
export function formatBalance(balance: bigint, decimals: number = 10): string {
    const divisor = BigInt(10 ** decimals);
    const whole = balance / divisor;
    const fraction = balance % divisor;
    return `${whole}.${fraction.toString().padStart(decimals, '0')}`;
}

/**
 * Check if an address is valid Polkadot address format
 * @param address - Address to validate
 */
export function isValidAddress(address: string): boolean {
    // Basic validation - Polkadot addresses are base58 encoded
    return address && address.length >= 47 && address.length <= 48;
}

/**
 * Create unique transaction ID from block number and index
 * @param blockNumber - Block number
 * @param index - Transaction index
 */
export function createTransactionId(blockNumber: bigint, index: number): string {
    return `${blockNumber}-${index}`;
}

/**
 * Convert timestamp to Unix timestamp
 * @param timestamp - Timestamp from block
 */
export function toUnixTimestamp(timestamp: Date): bigint {
    return BigInt(Math.floor(timestamp.getTime() / 1000));
}

/**
 * Calculate percentage change
 * @param oldValue - Previous value
 * @param newValue - Current value
 */
export function calculatePercentageChange(oldValue: bigint, newValue: bigint): number {
    if (oldValue === BigInt(0)) return 0;
    const change = newValue - oldValue;
    return Number((change * BigInt(100)) / oldValue);
}
