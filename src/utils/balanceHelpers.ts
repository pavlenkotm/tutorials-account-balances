// Balance calculation helper functions

import { BALANCE, NETWORK } from './constants';

/**
 * Convert Planck (smallest unit) to DOT
 * @param planck - Amount in Planck
 * @returns Amount in DOT
 */
export function planckToDot(planck: bigint): number {
    return Number(planck) / Number(BALANCE.ONE_DOT);
}

/**
 * Convert DOT to Planck (smallest unit)
 * @param dot - Amount in DOT
 * @returns Amount in Planck
 */
export function dotToPlanck(dot: number): bigint {
    return BigInt(Math.floor(dot * Number(BALANCE.ONE_DOT)));
}

/**
 * Calculate total balance including reserved amounts
 * @param free - Free balance
 * @param reserved - Reserved balance
 * @returns Total balance
 */
export function calculateTotalBalance(free: bigint, reserved: bigint): bigint {
    return free + reserved;
}

/**
 * Check if balance meets existential deposit requirement
 * @param balance - Balance to check
 * @returns True if balance meets requirement
 */
export function meetsExistentialDeposit(balance: bigint): boolean {
    return balance >= BALANCE.EXISTENTIAL_DEPOSIT;
}

/**
 * Calculate balance change percentage
 * @param oldBalance - Previous balance
 * @param newBalance - Current balance
 * @returns Percentage change
 */
export function calculateBalanceChange(oldBalance: bigint, newBalance: bigint): number {
    if (oldBalance === BigInt(0)) {
        return newBalance > BigInt(0) ? 100 : 0;
    }

    const change = newBalance - oldBalance;
    const percentageChange = (Number(change) / Number(oldBalance)) * 100;

    return Math.round(percentageChange * 100) / 100; // Round to 2 decimal places
}

/**
 * Format balance for display
 * @param balance - Balance in Planck
 * @param includeSymbol - Include currency symbol
 * @returns Formatted balance string
 */
export function formatBalanceDisplay(balance: bigint, includeSymbol: boolean = true): string {
    const dot = planckToDot(balance);
    const formatted = dot.toLocaleString('en-US', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 4
    });

    return includeSymbol ? `${formatted} ${NETWORK.SYMBOL}` : formatted;
}

/**
 * Calculate average balance from array of balances
 * @param balances - Array of balances
 * @returns Average balance
 */
export function calculateAverageBalance(balances: bigint[]): bigint {
    if (balances.length === 0) return BigInt(0);

    const total = balances.reduce((sum, balance) => sum + balance, BigInt(0));
    return total / BigInt(balances.length);
}

/**
 * Find median balance from array of balances
 * @param balances - Array of balances
 * @returns Median balance
 */
export function findMedianBalance(balances: bigint[]): bigint {
    if (balances.length === 0) return BigInt(0);

    const sorted = [...balances].sort((a, b) => (a < b ? -1 : a > b ? 1 : 0));
    const mid = Math.floor(sorted.length / 2);

    if (sorted.length % 2 === 0) {
        return (sorted[mid - 1] + sorted[mid]) / BigInt(2);
    }

    return sorted[mid];
}

/**
 * Check if transfer amount is valid
 * @param amount - Transfer amount
 * @param senderBalance - Sender's balance
 * @returns True if transfer is valid
 */
export function isValidTransfer(amount: bigint, senderBalance: bigint): boolean {
    return amount > BigInt(0) &&
           amount >= BALANCE.MIN_TRANSFER &&
           senderBalance >= amount;
}

/**
 * Calculate transferable balance (excluding existential deposit)
 * @param balance - Total balance
 * @returns Transferable balance
 */
export function calculateTransferableBalance(balance: bigint): bigint {
    const transferable = balance - BALANCE.EXISTENTIAL_DEPOSIT;
    return transferable > BigInt(0) ? transferable : BigInt(0);
}
