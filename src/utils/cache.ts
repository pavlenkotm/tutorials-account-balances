// Simple in-memory cache implementation
import { logger } from '@subql/node';

/**
 * Cache entry with expiration
 */
interface CacheEntry<T> {
    value: T;
    expiresAt: number;
}

/**
 * Simple cache class
 */
export class SimpleCache<T> {
    private cache: Map<string, CacheEntry<T>>;
    private defaultTTL: number;

    constructor(defaultTTL: number = 300) {
        // Default TTL: 5 minutes
        this.cache = new Map();
        this.defaultTTL = defaultTTL;
    }

    /**
     * Set cache entry
     */
    set(key: string, value: T, ttl?: number): void {
        const expiresAt = Date.now() + (ttl || this.defaultTTL) * 1000;
        this.cache.set(key, { value, expiresAt });
    }

    /**
     * Get cache entry
     */
    get(key: string): T | undefined {
        const entry = this.cache.get(key);

        if (!entry) {
            return undefined;
        }

        // Check if expired
        if (Date.now() > entry.expiresAt) {
            this.cache.delete(key);
            return undefined;
        }

        return entry.value;
    }

    /**
     * Check if key exists and is not expired
     */
    has(key: string): boolean {
        return this.get(key) !== undefined;
    }

    /**
     * Delete cache entry
     */
    delete(key: string): boolean {
        return this.cache.delete(key);
    }

    /**
     * Clear all cache entries
     */
    clear(): void {
        this.cache.clear();
    }

    /**
     * Get cache size
     */
    size(): number {
        return this.cache.size;
    }

    /**
     * Clean expired entries
     */
    cleanup(): number {
        const now = Date.now();
        let removed = 0;

        for (const [key, entry] of this.cache.entries()) {
            if (now > entry.expiresAt) {
                this.cache.delete(key);
                removed++;
            }
        }

        return removed;
    }

    /**
     * Get or set pattern - fetch if not in cache
     */
    async getOrSet(
        key: string,
        fetchFn: () => Promise<T>,
        ttl?: number
    ): Promise<T> {
        const cached = this.get(key);

        if (cached !== undefined) {
            return cached;
        }

        const value = await fetchFn();
        this.set(key, value, ttl);

        return value;
    }
}

/**
 * LRU Cache implementation
 */
export class LRUCache<T> {
    private cache: Map<string, { value: T; timestamp: number }>;
    private maxSize: number;

    constructor(maxSize: number = 100) {
        this.cache = new Map();
        this.maxSize = maxSize;
    }

    /**
     * Set cache entry (removes oldest if at capacity)
     */
    set(key: string, value: T): void {
        // Remove if already exists
        if (this.cache.has(key)) {
            this.cache.delete(key);
        }

        // Remove oldest if at capacity
        if (this.cache.size >= this.maxSize) {
            const firstKey = this.cache.keys().next().value;
            this.cache.delete(firstKey);
        }

        this.cache.set(key, { value, timestamp: Date.now() });
    }

    /**
     * Get cache entry and update access time
     */
    get(key: string): T | undefined {
        const entry = this.cache.get(key);

        if (!entry) {
            return undefined;
        }

        // Move to end (most recently used)
        this.cache.delete(key);
        this.cache.set(key, { ...entry, timestamp: Date.now() });

        return entry.value;
    }

    /**
     * Check if key exists
     */
    has(key: string): boolean {
        return this.cache.has(key);
    }

    /**
     * Delete cache entry
     */
    delete(key: string): boolean {
        return this.cache.delete(key);
    }

    /**
     * Clear all cache entries
     */
    clear(): void {
        this.cache.clear();
    }

    /**
     * Get cache size
     */
    size(): number {
        return this.cache.size;
    }
}

/**
 * Cache value types
 */
export interface CachedAccount {
    id: string;
    balance: bigint;
    lastUpdated: bigint;
}

export interface CachedTransfer {
    id: string;
    from: string;
    to: string;
    amount: bigint;
    blockNumber: bigint;
}

export interface CachedStatistics {
    totalAccounts: number;
    totalTransfers: number;
    totalVolume: bigint;
    lastUpdated: bigint;
}

/**
 * Global cache instances with proper typing
 */
export const accountCache = new SimpleCache<CachedAccount>(600); // 10 minutes
export const transferCache = new LRUCache<CachedTransfer>(1000);
export const statisticsCache = new SimpleCache<CachedStatistics>(300); // 5 minutes

/**
 * Auto-cleanup interval for SimpleCache instances
 */
const CLEANUP_INTERVAL = 60000; // 1 minute

// Start periodic cleanup for TTL-based caches
if (typeof setInterval !== 'undefined') {
    setInterval(() => {
        const accountRemoved = accountCache.cleanup();
        const statsRemoved = statisticsCache.cleanup();

        if (accountRemoved > 0 || statsRemoved > 0) {
            logger.info(`Cache cleanup: removed ${accountRemoved} accounts, ${statsRemoved} stats`);
        }
    }, CLEANUP_INTERVAL);
}

/**
 * Cache key builders
 */
export const CacheKeys = {
    account: (address: string) => `account:${address}`,
    transfer: (id: string) => `transfer:${id}`,
    accountMetadata: (address: string) => `metadata:${address}`,
    statistics: () => 'stats:global',
    blockTransfers: (blockNumber: bigint) => `block:${blockNumber}:transfers`,
};
