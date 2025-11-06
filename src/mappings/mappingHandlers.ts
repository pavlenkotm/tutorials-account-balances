import {SubstrateEvent} from "@subql/types";
import {Account, Transfer} from "../types";
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


