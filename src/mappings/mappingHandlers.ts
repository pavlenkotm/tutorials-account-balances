import {SubstrateEvent} from "@subql/types";
import {Account, Transfer, AccountMetadata} from "../types";
import {Balance} from "@polkadot/types/interfaces";

export async function handleEvent(event: SubstrateEvent): Promise<void> {
    const {event: {data: [account, balance]}} = event;
     //Create a new Account entity with ID using block hash
    let record = new Account(event.extrinsic.block.block.header.hash.toString());
    // Assign the Polkadot address to the account field
    record.account = account.toString();
    // Assign the balance to the balance field "type cast as Balance"
    record.balance = (balance as Balance).toBigInt();
    await record.save();
}

export async function handleTransfer(event: SubstrateEvent): Promise<void> {
    const {event: {data: [from, to, amount]}} = event;

    // Create a new Transfer entity with a unique ID
    const transfer = new Transfer(`${event.block.block.header.number}-${event.idx}`);
    transfer.from = from.toString();
    transfer.to = to.toString();
    transfer.amount = (amount as Balance).toBigInt();
    transfer.blockNumber = event.block.block.header.number.toBigInt();
    transfer.timestamp = event.block.timestamp;
    transfer.extrinsicHash = event.extrinsic?.extrinsic.hash.toString();

    await transfer.save();
}

export async function updateAccountMetadata(event: SubstrateEvent, accountAddress: string, amountReceived?: bigint, amountSent?: bigint): Promise<void> {
    const blockNumber = event.block.block.header.number.toBigInt();

    // Try to load existing metadata or create new
    let metadata = await AccountMetadata.get(accountAddress);

    if (!metadata) {
        metadata = new AccountMetadata(accountAddress);
        metadata.account = accountAddress;
        metadata.firstSeenBlock = blockNumber;
        metadata.transactionCount = BigInt(0);
        metadata.totalReceived = BigInt(0);
        metadata.totalSent = BigInt(0);
    }

    metadata.lastActiveBlock = blockNumber;
    metadata.transactionCount = metadata.transactionCount + BigInt(1);

    if (amountReceived) {
        metadata.totalReceived = metadata.totalReceived + amountReceived;
    }

    if (amountSent) {
        metadata.totalSent = metadata.totalSent + amountSent;
    }

    await metadata.save();
}


