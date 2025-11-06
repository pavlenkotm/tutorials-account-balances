// Custom TypeScript types for SubQuery indexer

/**
 * Event data interface
 */
export interface EventData {
    blockNumber: bigint;
    timestamp: bigint;
    extrinsicHash?: string;
}

/**
 * Transfer event data
 */
export interface TransferEventData extends EventData {
    from: string;
    to: string;
    amount: bigint;
}

/**
 * Balance event data
 */
export interface BalanceEventData extends EventData {
    account: string;
    balance: bigint;
}

/**
 * Account summary statistics
 */
export interface AccountSummary {
    address: string;
    balance: bigint;
    transactionCount: number;
    firstSeen: bigint;
    lastActive: bigint;
}

/**
 * Transfer summary
 */
export interface TransferSummary {
    totalTransfers: number;
    totalVolume: bigint;
    averageAmount: bigint;
}

/**
 * Block info
 */
export interface BlockInfo {
    number: bigint;
    hash: string;
    timestamp: bigint;
    parentHash: string;
}

/**
 * Statistics snapshot
 */
export interface StatsSnapshot {
    totalAccounts: number;
    totalTransfers: number;
    totalVolume: bigint;
    blockNumber: bigint;
}

/**
 * Handler context
 */
export interface HandlerContext {
    blockNumber: bigint;
    blockHash: string;
    timestamp: bigint;
}

/**
 * Query options
 */
export interface QueryOptions {
    limit?: number;
    offset?: number;
    orderBy?: string;
    orderDirection?: 'ASC' | 'DESC';
}

/**
 * Pagination result
 */
export interface PaginatedResult<T> {
    data: T[];
    total: number;
    hasNext: boolean;
}
