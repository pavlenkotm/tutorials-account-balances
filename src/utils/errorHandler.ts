// Error handling utilities

/**
 * Custom error types
 */
export enum ErrorType {
    VALIDATION_ERROR = 'VALIDATION_ERROR',
    PROCESSING_ERROR = 'PROCESSING_ERROR',
    DATABASE_ERROR = 'DATABASE_ERROR',
    NETWORK_ERROR = 'NETWORK_ERROR',
}

/**
 * Custom error class
 */
export class SubQueryError extends Error {
    type: ErrorType;
    context?: any;

    constructor(message: string, type: ErrorType, context?: any) {
        super(message);
        this.name = 'SubQueryError';
        this.type = type;
        this.context = context;
    }
}

/**
 * Handle validation errors
 */
export function handleValidationError(field: string, value: any): SubQueryError {
    return new SubQueryError(
        `Validation failed for field: ${field}`,
        ErrorType.VALIDATION_ERROR,
        { field, value }
    );
}

/**
 * Handle processing errors
 */
export function handleProcessingError(operation: string, error: Error): SubQueryError {
    return new SubQueryError(
        `Processing error in ${operation}: ${error.message}`,
        ErrorType.PROCESSING_ERROR,
        { operation, originalError: error }
    );
}

/**
 * Handle database errors
 */
export function handleDatabaseError(operation: string, error: Error): SubQueryError {
    return new SubQueryError(
        `Database error during ${operation}: ${error.message}`,
        ErrorType.DATABASE_ERROR,
        { operation, originalError: error }
    );
}

/**
 * Safe wrapper for async operations
 */
export async function safeExecute<T>(
    operation: () => Promise<T>,
    errorMessage: string
): Promise<T | null> {
    try {
        return await operation();
    } catch (error) {
        logger.error(`${errorMessage}: ${error}`);
        return null;
    }
}

/**
 * Retry wrapper for operations
 */
export async function retryOperation<T>(
    operation: () => Promise<T>,
    maxRetries: number = 3,
    delay: number = 1000
): Promise<T> {
    let lastError: Error | undefined;

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            return await operation();
        } catch (error) {
            lastError = error as Error;
            logger.warn(`Attempt ${attempt} failed: ${error}`);

            if (attempt < maxRetries) {
                await new Promise(resolve => setTimeout(resolve, delay * attempt));
            }
        }
    }

    throw new SubQueryError(
        `Operation failed after ${maxRetries} attempts`,
        ErrorType.PROCESSING_ERROR,
        { lastError }
    );
}

/**
 * Log error with context
 */
export function logError(error: Error | SubQueryError, context?: any): void {
    const errorInfo = {
        message: error.message,
        name: error.name,
        stack: error.stack,
        ...(error instanceof SubQueryError && {
            type: error.type,
            errorContext: error.context,
        }),
        ...context,
    };

    logger.error(JSON.stringify(errorInfo, null, 2));
}

/**
 * Check if error is retryable
 */
export function isRetryableError(error: Error): boolean {
    const retryableMessages = [
        'timeout',
        'network',
        'connection',
        'ECONNRESET',
        'ETIMEDOUT',
    ];

    return retryableMessages.some(msg =>
        error.message.toLowerCase().includes(msg.toLowerCase())
    );
}
