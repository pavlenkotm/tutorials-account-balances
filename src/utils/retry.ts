// Retry utility with exponential backoff
import { logger } from '@subql/node';

/**
 * Retry configuration
 */
export interface RetryConfig {
    maxAttempts?: number;
    initialDelay?: number;
    maxDelay?: number;
    backoffFactor?: number;
    retryableErrors?: string[];
}

/**
 * Default retry configuration
 */
const DEFAULT_CONFIG: Required<RetryConfig> = {
    maxAttempts: 3,
    initialDelay: 1000, // 1 second
    maxDelay: 30000, // 30 seconds
    backoffFactor: 2,
    retryableErrors: ['ECONNRESET', 'ETIMEDOUT', 'ECONNREFUSED', 'EHOSTUNREACH'],
};

/**
 * Sleep for specified milliseconds
 */
const sleep = (ms: number): Promise<void> =>
    new Promise((resolve) => setTimeout(resolve, ms));

/**
 * Check if error is retryable
 */
function isRetryableError(error: unknown, retryableErrors: string[]): boolean {
    if (!error || typeof error !== 'object') return false;

    const errorCode = (error as { code?: string }).code;
    const errorMessage = (error as Error).message || '';

    return (
        (errorCode && retryableErrors.includes(errorCode)) ||
        retryableErrors.some((pattern) => errorMessage.includes(pattern))
    );
}

/**
 * Execute function with retry logic and exponential backoff
 */
export async function withRetry<T>(
    fn: () => Promise<T>,
    config: RetryConfig = {},
    context?: string
): Promise<T> {
    const {
        maxAttempts,
        initialDelay,
        maxDelay,
        backoffFactor,
        retryableErrors,
    } = { ...DEFAULT_CONFIG, ...config };

    let lastError: unknown;
    let delay = initialDelay;

    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
            return await fn();
        } catch (error) {
            lastError = error;

            // Don't retry if it's the last attempt
            if (attempt === maxAttempts) {
                break;
            }

            // Check if error is retryable
            if (!isRetryableError(error, retryableErrors)) {
                logger.warn(
                    `${context ? `[${context}] ` : ''}Non-retryable error encountered`
                );
                throw error;
            }

            // Log retry attempt
            logger.warn(
                `${context ? `[${context}] ` : ''}Attempt ${attempt}/${maxAttempts} failed. ` +
                    `Retrying in ${delay}ms... Error: ${error instanceof Error ? error.message : String(error)}`
            );

            // Wait before retrying
            await sleep(delay);

            // Calculate next delay with exponential backoff
            delay = Math.min(delay * backoffFactor, maxDelay);
        }
    }

    // All attempts failed
    logger.error(
        `${context ? `[${context}] ` : ''}All ${maxAttempts} attempts failed. ` +
            `Last error: ${lastError instanceof Error ? lastError.message : String(lastError)}`
    );

    throw lastError;
}

/**
 * Retry decorator for class methods
 */
export function Retry(config: RetryConfig = {}) {
    return function (
        target: unknown,
        propertyKey: string,
        descriptor: PropertyDescriptor
    ) {
        const originalMethod = descriptor.value;

        descriptor.value = async function (...args: unknown[]) {
            return withRetry(
                () => originalMethod.apply(this, args),
                config,
                `${target?.constructor?.name}.${propertyKey}`
            );
        };

        return descriptor;
    };
}

/**
 * Batch retry - retry multiple operations with individual retry logic
 */
export async function batchRetry<T>(
    operations: Array<() => Promise<T>>,
    config: RetryConfig = {}
): Promise<Array<T | Error>> {
    return Promise.all(
        operations.map((op, index) =>
            withRetry(op, config, `Batch operation ${index + 1}`)
                .catch((error) => error as Error)
        )
    );
}

/**
 * Circuit breaker state
 */
enum CircuitState {
    CLOSED = 'CLOSED',
    OPEN = 'OPEN',
    HALF_OPEN = 'HALF_OPEN',
}

/**
 * Circuit breaker configuration
 */
export interface CircuitBreakerConfig {
    failureThreshold?: number;
    resetTimeout?: number;
    monitoringPeriod?: number;
}

/**
 * Circuit breaker pattern implementation
 */
export class CircuitBreaker {
    private state: CircuitState = CircuitState.CLOSED;
    private failureCount = 0;
    private lastFailureTime = 0;
    private successCount = 0;

    private readonly failureThreshold: number;
    private readonly resetTimeout: number;
    private readonly monitoringPeriod: number;

    constructor(config: CircuitBreakerConfig = {}) {
        this.failureThreshold = config.failureThreshold ?? 5;
        this.resetTimeout = config.resetTimeout ?? 60000; // 1 minute
        this.monitoringPeriod = config.monitoringPeriod ?? 10000; // 10 seconds
    }

    async execute<T>(
        fn: () => Promise<T>,
        context?: string
    ): Promise<T> {
        // Check if circuit should transition to HALF_OPEN
        if (
            this.state === CircuitState.OPEN &&
            Date.now() - this.lastFailureTime >= this.resetTimeout
        ) {
            this.state = CircuitState.HALF_OPEN;
            this.successCount = 0;
            logger.info(`${context ? `[${context}] ` : ''}Circuit breaker: OPEN -> HALF_OPEN`);
        }

        // Reject immediately if circuit is OPEN
        if (this.state === CircuitState.OPEN) {
            throw new Error(
                `Circuit breaker is OPEN. ${context ? `Context: ${context}` : ''}`
            );
        }

        try {
            const result = await fn();

            // Record success
            this.onSuccess(context);

            return result;
        } catch (error) {
            // Record failure
            this.onFailure(context);

            throw error;
        }
    }

    private onSuccess(context?: string): void {
        this.failureCount = 0;

        if (this.state === CircuitState.HALF_OPEN) {
            this.successCount++;

            // If enough successes in HALF_OPEN, close the circuit
            if (this.successCount >= 2) {
                this.state = CircuitState.CLOSED;
                logger.info(`${context ? `[${context}] ` : ''}Circuit breaker: HALF_OPEN -> CLOSED`);
            }
        }
    }

    private onFailure(context?: string): void {
        this.failureCount++;
        this.lastFailureTime = Date.now();

        // If in HALF_OPEN and a failure occurs, reopen the circuit
        if (this.state === CircuitState.HALF_OPEN) {
            this.state = CircuitState.OPEN;
            logger.warn(`${context ? `[${context}] ` : ''}Circuit breaker: HALF_OPEN -> OPEN`);
            return;
        }

        // If failure threshold exceeded, open the circuit
        if (this.failureCount >= this.failureThreshold) {
            this.state = CircuitState.OPEN;
            logger.warn(
                `${context ? `[${context}] ` : ''}Circuit breaker: CLOSED -> OPEN ` +
                    `(${this.failureCount} failures)`
            );
        }
    }

    getState(): CircuitState {
        return this.state;
    }

    getFailureCount(): number {
        return this.failureCount;
    }

    reset(): void {
        this.state = CircuitState.CLOSED;
        this.failureCount = 0;
        this.successCount = 0;
        this.lastFailureTime = 0;
    }
}
