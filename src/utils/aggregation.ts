// Data aggregation utilities

/**
 * Aggregate transfer data by time period
 */
export interface TimeSeriesData {
    timestamp: bigint;
    count: number;
    totalVolume: bigint;
    averageAmount: bigint;
}

/**
 * Aggregate transfers by day
 */
export function aggregateByDay(transfers: any[]): Map<string, TimeSeriesData> {
    const dailyData = new Map<string, TimeSeriesData>();

    for (const transfer of transfers) {
        const day = getDateKey(Number(transfer.timestamp));

        if (!dailyData.has(day)) {
            dailyData.set(day, {
                timestamp: transfer.timestamp,
                count: 0,
                totalVolume: BigInt(0),
                averageAmount: BigInt(0),
            });
        }

        const data = dailyData.get(day)!;
        data.count++;
        data.totalVolume += transfer.amount;
        data.averageAmount = data.totalVolume / BigInt(data.count);
    }

    return dailyData;
}

/**
 * Get date key for aggregation (YYYY-MM-DD)
 */
export function getDateKey(timestamp: number): string {
    const date = new Date(timestamp * 1000);
    return date.toISOString().split('T')[0];
}

/**
 * Calculate top accounts by volume
 */
export interface AccountVolume {
    account: string;
    totalSent: bigint;
    totalReceived: bigint;
    netFlow: bigint;
    transactionCount: number;
}

/**
 * Aggregate account volumes
 */
export function aggregateAccountVolumes(transfers: any[]): Map<string, AccountVolume> {
    const volumes = new Map<string, AccountVolume>();

    for (const transfer of transfers) {
        // Process sender
        if (!volumes.has(transfer.from)) {
            volumes.set(transfer.from, {
                account: transfer.from,
                totalSent: BigInt(0),
                totalReceived: BigInt(0),
                netFlow: BigInt(0),
                transactionCount: 0,
            });
        }

        const senderData = volumes.get(transfer.from)!;
        senderData.totalSent += transfer.amount;
        senderData.netFlow -= transfer.amount;
        senderData.transactionCount++;

        // Process receiver
        if (!volumes.has(transfer.to)) {
            volumes.set(transfer.to, {
                account: transfer.to,
                totalSent: BigInt(0),
                totalReceived: BigInt(0),
                netFlow: BigInt(0),
                transactionCount: 0,
            });
        }

        const receiverData = volumes.get(transfer.to)!;
        receiverData.totalReceived += transfer.amount;
        receiverData.netFlow += transfer.amount;
        receiverData.transactionCount++;
    }

    return volumes;
}

/**
 * Calculate percentiles
 */
export function calculatePercentile(values: bigint[], percentile: number): bigint {
    if (values.length === 0) return BigInt(0);

    const sorted = [...values].sort((a, b) => (a < b ? -1 : a > b ? 1 : 0));
    const index = Math.ceil((percentile / 100) * sorted.length) - 1;

    return sorted[Math.max(0, index)];
}

/**
 * Calculate statistics for an array of values
 */
export interface Statistics {
    min: bigint;
    max: bigint;
    mean: bigint;
    median: bigint;
    p95: bigint;
    p99: bigint;
}

export function calculateStatistics(values: bigint[]): Statistics {
    if (values.length === 0) {
        return {
            min: BigInt(0),
            max: BigInt(0),
            mean: BigInt(0),
            median: BigInt(0),
            p95: BigInt(0),
            p99: BigInt(0),
        };
    }

    const sorted = [...values].sort((a, b) => (a < b ? -1 : a > b ? 1 : 0));
    const sum = values.reduce((acc, val) => acc + val, BigInt(0));

    return {
        min: sorted[0],
        max: sorted[sorted.length - 1],
        mean: sum / BigInt(values.length),
        median: calculatePercentile(values, 50),
        p95: calculatePercentile(values, 95),
        p99: calculatePercentile(values, 99),
    };
}

/**
 * Group transfers by account
 */
export function groupTransfersByAccount(transfers: any[]): Map<string, any[]> {
    const grouped = new Map<string, any[]>();

    for (const transfer of transfers) {
        // Add to sender's list
        if (!grouped.has(transfer.from)) {
            grouped.set(transfer.from, []);
        }
        grouped.get(transfer.from)!.push({ ...transfer, type: 'sent' });

        // Add to receiver's list
        if (!grouped.has(transfer.to)) {
            grouped.set(transfer.to, []);
        }
        grouped.get(transfer.to)!.push({ ...transfer, type: 'received' });
    }

    return grouped;
}

/**
 * Calculate transaction frequency
 */
export interface FrequencyData {
    hourly: number;
    daily: number;
    weekly: number;
}

export function calculateFrequency(
    transactions: any[],
    currentTimestamp: number
): FrequencyData {
    const hour = 3600;
    const day = 86400;
    const week = 604800;

    const recentHour = transactions.filter(
        tx => currentTimestamp - Number(tx.timestamp) <= hour
    ).length;

    const recentDay = transactions.filter(
        tx => currentTimestamp - Number(tx.timestamp) <= day
    ).length;

    const recentWeek = transactions.filter(
        tx => currentTimestamp - Number(tx.timestamp) <= week
    ).length;

    return {
        hourly: recentHour,
        daily: recentDay,
        weekly: recentWeek,
    };
}
