// Statistics tracking handler

import { Statistics } from "../types";
import { STATS } from "../utils/constants";

/**
 * Get or create global statistics entity
 */
export async function getOrCreateStatistics(): Promise<Statistics> {
    let stats = await Statistics.get(STATS.GLOBAL_ID);

    if (!stats) {
        stats = new Statistics(STATS.GLOBAL_ID);
        stats.totalAccounts = BigInt(0);
        stats.totalTransfers = BigInt(0);
        stats.totalVolume = BigInt(0);
        stats.lastUpdatedBlock = BigInt(0);
    }

    return stats;
}

/**
 * Update statistics with new account
 * @param blockNumber - Current block number
 */
export async function incrementAccountCount(blockNumber: bigint): Promise<void> {
    const stats = await getOrCreateStatistics();
    stats.totalAccounts = stats.totalAccounts + BigInt(1);
    stats.lastUpdatedBlock = blockNumber;
    await stats.save();
}

/**
 * Update statistics with new transfer
 * @param amount - Transfer amount
 * @param blockNumber - Current block number
 */
export async function recordTransfer(amount: bigint, blockNumber: bigint): Promise<void> {
    const stats = await getOrCreateStatistics();
    stats.totalTransfers = stats.totalTransfers + BigInt(1);
    stats.totalVolume = stats.totalVolume + amount;
    stats.lastUpdatedBlock = blockNumber;
    await stats.save();
}

/**
 * Get current statistics
 */
export async function getCurrentStatistics(): Promise<Statistics | undefined> {
    return await Statistics.get(STATS.GLOBAL_ID);
}

/**
 * Update statistics last block
 * @param blockNumber - Current block number
 */
export async function updateLastBlock(blockNumber: bigint): Promise<void> {
    const stats = await getOrCreateStatistics();
    stats.lastUpdatedBlock = blockNumber;
    await stats.save();
}
