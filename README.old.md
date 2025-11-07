# What is SubQuery?

SubQuery powers the next generation of Polkadot dApps by allowing developers to extract, transform and query blockchain data in real time using GraphQL. In addition to this, SubQuery provides production quality hosting infrastructure to run these projects in.

# SubQuery Example - Account Balance & Transfer Tracker

This enhanced SubQuery project provides comprehensive blockchain data indexing for Polkadot, including:

- **Account Balances**: Track deposit balances for all accounts
- **Transfer Events**: Monitor and record all DOT transfers
- **Transaction History**: Complete transaction history for each account
- **Account Metadata**: Detailed statistics including first seen, last active, and transaction counts
- **Network Statistics**: Global analytics including total accounts, transfers, and volume

## Features

- ✅ Account balance tracking from deposit events
- ✅ Transfer event monitoring and indexing
- ✅ Transaction history with complete metadata
- ✅ Account activity statistics and analytics
- ✅ Global network metrics and statistics
- ✅ Comprehensive validation utilities
- ✅ Balance calculation and formatting helpers
- ✅ Data aggregation and analytics functions
- ✅ Advanced error handling and logging
- ✅ Performance optimization with caching
- ✅ Rich formatting utilities for output

# Getting Started

### 1. Clone the entire subql-example repository

```shell
git clone https://github.com/subquery/tutorials-account-balances.git

```

### 2. Install dependencies

```shell
cd tutorials-account-balance
yarn
```

### 3. Generate types

```shell
yarn codegen
```

### 4. Build the project

```shell
yarn build
```

### 5. Start Docker

```shell
docker-compose pull & docker-compose up
```

### 6. Run locally

Open http://localhost:3000/ on your browser

### 7. Example query to run

```shell
query {
   accounts(first:10 orderBy:BALANCE_DESC){
    nodes{
      account
      balance
    }
  }
}
```

# Understanding this project

This project includes multiple event handlers and utilities:

## Event Handlers

1. **handleEvent**: Processes deposit events using the `balances/Deposit` filter
2. **handleTransfer**: Tracks all transfer events using the `balances/Transfer` filter
3. **updateAccountMetadata**: Maintains account statistics and metadata

## Utilities

The project includes comprehensive utility modules in `src/utils/`:

- **helpers.ts**: General helper functions for formatting and validation
- **validators.ts**: Blockchain data validation functions
- **constants.ts**: Network constants and configuration
- **balanceHelpers.ts**: Balance calculation and conversion utilities
- **formatting.ts**: Output formatting for various data types
- **errorHandler.ts**: Error handling and retry mechanisms
- **aggregation.ts**: Data aggregation and analytics functions
- **cache.ts**: Caching utilities for performance optimization

## Schema Entities

The [schema.graphql](https://doc.subquery.network/create/graphql.html) file defines:

- **Account**: Stores account balances
- **Transfer**: Records all transfer events
- **TransactionHistory**: Comprehensive transaction records
- **AccountMetadata**: Account activity statistics
- **Statistics**: Global network metrics

## Additional Resources

- See [API.md](./API.md) for detailed API documentation
- See [queries.graphql](./queries.graphql) for example queries
