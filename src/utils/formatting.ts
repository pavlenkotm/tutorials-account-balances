// Formatting utilities for display and output

import { NETWORK } from './constants';

/**
 * Format address for display (truncated)
 */
export function formatAddress(address: string, length: number = 8): string {
    if (!address || address.length <= length * 2) {
        return address;
    }

    return `${address.slice(0, length)}...${address.slice(-length)}`;
}

/**
 * Format timestamp to human-readable date
 */
export function formatTimestamp(timestamp: bigint | number): string {
    const ts = typeof timestamp === 'bigint' ? Number(timestamp) : timestamp;
    const date = new Date(ts * 1000);

    return date.toISOString();
}

/**
 * Format timestamp to relative time
 */
export function formatRelativeTime(timestamp: bigint | number): string {
    const ts = typeof timestamp === 'bigint' ? Number(timestamp) : timestamp;
    const now = Math.floor(Date.now() / 1000);
    const diff = now - ts;

    if (diff < 60) return `${diff} seconds ago`;
    if (diff < 3600) return `${Math.floor(diff / 60)} minutes ago`;
    if (diff < 86400) return `${Math.floor(diff / 3600)} hours ago`;
    if (diff < 604800) return `${Math.floor(diff / 86400)} days ago`;
    if (diff < 2592000) return `${Math.floor(diff / 604800)} weeks ago`;

    return `${Math.floor(diff / 2592000)} months ago`;
}

/**
 * Format large numbers with separators
 */
export function formatNumber(num: bigint | number): string {
    const n = typeof num === 'bigint' ? Number(num) : num;
    return n.toLocaleString('en-US');
}

/**
 * Format balance with proper decimal places
 */
export function formatBalance(
    balance: bigint,
    decimals: number = NETWORK.DECIMALS,
    includeSymbol: boolean = true
): string {
    const divisor = BigInt(10 ** decimals);
    const whole = balance / divisor;
    const fraction = balance % divisor;

    const fractionStr = fraction.toString().padStart(decimals, '0');
    const trimmedFraction = fractionStr.replace(/0+$/, '').slice(0, 4);

    const formatted = trimmedFraction
        ? `${formatNumber(whole)}.${trimmedFraction}`
        : formatNumber(whole);

    return includeSymbol ? `${formatted} ${NETWORK.SYMBOL}` : formatted;
}

/**
 * Format hash for display
 */
export function formatHash(hash: string, length: number = 10): string {
    if (!hash || hash.length <= length * 2) {
        return hash;
    }

    return `${hash.slice(0, length + 2)}...${hash.slice(-length)}`;
}

/**
 * Format block number
 */
export function formatBlockNumber(blockNumber: bigint | number): string {
    return `#${formatNumber(blockNumber)}`;
}

/**
 * Format percentage
 */
export function formatPercentage(value: number, decimals: number = 2): string {
    return `${value.toFixed(decimals)}%`;
}

/**
 * Format transaction type
 */
export function formatTransactionType(type: string): string {
    return type
        .split('_')
        .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
        .join(' ');
}

/**
 * Format duration in seconds to human-readable
 */
export function formatDuration(seconds: number): string {
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;

    const parts: string[] = [];
    if (days > 0) parts.push(`${days}d`);
    if (hours > 0) parts.push(`${hours}h`);
    if (minutes > 0) parts.push(`${minutes}m`);
    if (secs > 0 || parts.length === 0) parts.push(`${secs}s`);

    return parts.join(' ');
}

/**
 * Format file size
 */
export function formatFileSize(bytes: number): string {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    let size = bytes;
    let unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
        size /= 1024;
        unitIndex++;
    }

    return `${size.toFixed(2)} ${units[unitIndex]}`;
}

/**
 * Format JSON for pretty printing
 */
export function formatJSON(obj: any, indent: number = 2): string {
    return JSON.stringify(
        obj,
        (key, value) => (typeof value === 'bigint' ? value.toString() : value),
        indent
    );
}

/**
 * Format CSV line
 */
export function formatCSV(values: any[]): string {
    return values
        .map(v => {
            const str = String(v);
            // Escape quotes and wrap in quotes if contains comma or quote
            if (str.includes(',') || str.includes('"') || str.includes('\n')) {
                return `"${str.replace(/"/g, '""')}"`;
            }
            return str;
        })
        .join(',');
}
