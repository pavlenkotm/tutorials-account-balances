// Constants for Polkadot SubQuery indexer

/**
 * Network constants
 */
export const NETWORK = {
    NAME: 'Polkadot',
    DECIMALS: 10,
    SYMBOL: 'DOT',
    SS58_PREFIX: 0,
} as const;

/**
 * Balance constants
 */
export const BALANCE = {
    ONE_DOT: BigInt(10_000_000_000), // 10^10 Planck
    MIN_TRANSFER: BigInt(1_000_000), // Minimum transfer amount
    EXISTENTIAL_DEPOSIT: BigInt(1_000_000_000), // 0.1 DOT in Planck
} as const;

/**
 * Event types
 */
export const EVENT_TYPES = {
    DEPOSIT: 'balances.Deposit',
    TRANSFER: 'balances.Transfer',
    WITHDRAW: 'balances.Withdraw',
    RESERVED: 'balances.Reserved',
    UNRESERVED: 'balances.Unreserved',
} as const;

/**
 * Transaction types
 */
export const TRANSACTION_TYPES = {
    TRANSFER: 'transfer',
    DEPOSIT: 'deposit',
    WITHDRAW: 'withdraw',
    RESERVE: 'reserve',
    UNRESERVE: 'unreserve',
} as const;

/**
 * Time constants (in seconds)
 */
export const TIME = {
    BLOCK_TIME: 6, // Average block time in seconds
    HOUR: 3600,
    DAY: 86400,
    WEEK: 604800,
} as const;

/**
 * Query limits
 */
export const LIMITS = {
    MAX_QUERY_RESULTS: 100,
    DEFAULT_PAGE_SIZE: 20,
} as const;

/**
 * Statistics constants
 */
export const STATS = {
    GLOBAL_ID: 'global-stats',
    UPDATE_INTERVAL: 100, // Update every N blocks
} as const;
