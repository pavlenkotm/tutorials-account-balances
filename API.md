# SubQuery API Documentation

## Overview

This SubQuery project provides a GraphQL API for querying Polkadot account balances, transfers, and statistics.

## Entities

### Account

Tracks account balances from deposit events.

**Fields:**
- `id` (ID!): Unique identifier (block hash)
- `account` (String): Polkadot address
- `balance` (BigInt): Account balance in Planck

### Transfer

Records all transfer events on the network.

**Fields:**
- `id` (ID!): Unique identifier (blockNumber-index)
- `from` (String!): Sender address
- `to` (String!): Recipient address
- `amount` (BigInt!): Transfer amount in Planck
- `blockNumber` (BigInt!): Block number
- `timestamp` (BigInt!): Block timestamp
- `extrinsicHash` (String): Transaction hash

### TransactionHistory

Comprehensive transaction history for accounts.

**Fields:**
- `id` (ID!): Unique identifier
- `account` (String!): Account address
- `transactionType` (String!): Type of transaction
- `amount` (BigInt!): Transaction amount
- `blockNumber` (BigInt!): Block number
- `timestamp` (BigInt!): Block timestamp
- `success` (Boolean!): Transaction success status
- `fee` (BigInt): Transaction fee

### AccountMetadata

Detailed metadata about account activity.

**Fields:**
- `id` (ID!): Account address
- `account` (String!): Account address
- `firstSeenBlock` (BigInt!): First appearance block
- `lastActiveBlock` (BigInt!): Last activity block
- `transactionCount` (BigInt!): Total transaction count
- `totalReceived` (BigInt!): Total amount received
- `totalSent` (BigInt!): Total amount sent

### Statistics

Global network statistics.

**Fields:**
- `id` (ID!): Statistics identifier
- `totalAccounts` (BigInt!): Total unique accounts
- `totalTransfers` (BigInt!): Total transfer count
- `totalVolume` (BigInt!): Total transfer volume
- `lastUpdatedBlock` (BigInt!): Last update block

## Common Queries

### Get Account Balance

```graphql
query {
  accounts(filter: { account: { equalTo: "1address..." } }) {
    nodes {
      account
      balance
    }
  }
}
```

### Get Recent Transfers

```graphql
query {
  transfers(first: 10, orderBy: BLOCK_NUMBER_DESC) {
    nodes {
      from
      to
      amount
      blockNumber
    }
  }
}
```

### Get Account Activity

```graphql
query {
  accountMetadatas(filter: { account: { equalTo: "1address..." } }) {
    nodes {
      transactionCount
      totalReceived
      totalSent
    }
  }
}
```

## Filters

You can filter results using various operators:

- `equalTo`: Exact match
- `greaterThan`: Greater than
- `lessThan`: Less than
- `greaterThanOrEqualTo`: Greater than or equal
- `lessThanOrEqualTo`: Less than or equal
- `in`: Match any in array
- `contains`: String contains
- `startsWith`: String starts with

## Ordering

Results can be ordered by any field:

```graphql
orderBy: FIELD_NAME_ASC  # or _DESC for descending
```

## Pagination

Use `first` and `offset` for pagination:

```graphql
query {
  accounts(first: 20, offset: 40) {
    nodes {
      account
      balance
    }
  }
}
```

## Rate Limiting

Please be mindful of rate limits when querying the API. For production use, consider implementing caching.

## Units

All balance and amount fields are in Planck (smallest unit):
- 1 DOT = 10,000,000,000 Planck (10^10)

## Support

For issues or questions, please refer to the SubQuery documentation at https://doc.subquery.network/
