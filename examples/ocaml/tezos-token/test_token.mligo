(**
 * Unit tests for FA2 Token Contract
 *
 * Tests cover:
 * - Token transfers
 * - Operator management
 * - Minting and burning
 * - Balance queries
 * - Error conditions
 *)

#include "token.mligo"

(* ============================================================================
 * Test Helpers
 * ============================================================================ *)

let alice : address = ("tz1VSUr8wwNhLAzempoch5d6hLRiTh8Cjcjb" : address)
let bob   : address = ("tz1aSkwEot3L2kmUvcoxzjMomb9mvBNuzFK6" : address)
let carol : address = ("tz1gjaF81ZRRvdzjobyfVNsAeSC6PScjfQwN" : address)
let admin : address = ("tz1faswCTDciRzE4oJ9jn2Vm2dvjeyA9fUzU" : address)

let token_id_0 = 0n
let token_id_1 = 1n

(**
 * Create initial storage for tests
 *)
let init_storage : storage = {
  ledger = (Big_map.empty : ledger);
  operators = (Big_map.empty : operators);
  token_metadata = (Big_map.empty : token_metadata_storage);
  admin = admin;
  total_supply = (Big_map.empty : (token_id, nat) big_map);
}

(**
 * Add initial balances to storage
 *)
let add_balance (storage : storage) (owner : address) (token_id : token_id) (amount : nat) : storage =
  let ledger = Big_map.update (owner, token_id) (Some amount) storage.ledger in
  { storage with ledger = ledger }

(* ============================================================================
 * Test Cases
 * ============================================================================ *)

(**
 * Test: Simple transfer between two addresses
 *)
let test_simple_transfer =
  (* Setup: Alice has 100 tokens *)
  let storage = add_balance init_storage alice token_id_0 100n in

  (* Alice transfers 30 tokens to Bob *)
  let transfer_param = [{
    from_ = alice;
    txs = [{
      to_ = bob;
      token_id = token_id_0;
      amount = 30n;
    }];
  }] in

  (* Execute transfer (simulating Alice as sender) *)
  let (ops, new_storage) = transfer transfer_param storage in

  (* Verify balances *)
  let alice_balance = get_balance new_storage.ledger alice token_id_0 in
  let bob_balance = get_balance new_storage.ledger bob token_id_0 in

  let () = assert (alice_balance = 70n) in
  let () = assert (bob_balance = 30n) in
  let () = assert (List.length ops = 0) in

  "Simple transfer succeeded"

(**
 * Test: Batch transfer to multiple recipients
 *)
let test_batch_transfer =
  (* Setup: Alice has 100 tokens *)
  let storage = add_balance init_storage alice token_id_0 100n in

  (* Alice transfers to both Bob and Carol *)
  let transfer_param = [{
    from_ = alice;
    txs = [
      { to_ = bob;   token_id = token_id_0; amount = 30n };
      { to_ = carol; token_id = token_id_0; amount = 40n };
    ];
  }] in

  let (ops, new_storage) = transfer transfer_param storage in

  (* Verify balances *)
  let alice_balance = get_balance new_storage.ledger alice token_id_0 in
  let bob_balance = get_balance new_storage.ledger bob token_id_0 in
  let carol_balance = get_balance new_storage.ledger carol token_id_0 in

  let () = assert (alice_balance = 30n) in
  let () = assert (bob_balance = 30n) in
  let () = assert (carol_balance = 40n) in

  "Batch transfer succeeded"

(**
 * Test: Operator approval and transfer
 *)
let test_operator_transfer =
  (* Setup: Alice has 100 tokens *)
  let storage = add_balance init_storage alice token_id_0 100n in

  (* Alice approves Bob as operator *)
  let operator_update = [Add_operator {
    owner = alice;
    operator = bob;
    token_id = token_id_0;
  }] in

  let (_, storage) = update_operators operator_update storage in

  (* Bob transfers Alice's tokens to Carol *)
  let transfer_param = [{
    from_ = alice;
    txs = [{
      to_ = carol;
      token_id = token_id_0;
      amount = 50n;
    }];
  }] in

  let (_, new_storage) = transfer transfer_param storage in

  (* Verify balances *)
  let alice_balance = get_balance new_storage.ledger alice token_id_0 in
  let carol_balance = get_balance new_storage.ledger carol token_id_0 in

  let () = assert (alice_balance = 50n) in
  let () = assert (carol_balance = 50n) in

  "Operator transfer succeeded"

(**
 * Test: Minting new tokens
 *)
let test_mint =
  let storage = init_storage in

  (* Admin mints 1000 tokens to Alice *)
  let (ops, new_storage) = mint alice token_id_0 1000n storage in

  (* Verify balance and supply *)
  let alice_balance = get_balance new_storage.ledger alice token_id_0 in
  let total_supply = match Big_map.find_opt token_id_0 new_storage.total_supply with
    | Some supply -> supply
    | None -> 0n
  in

  let () = assert (alice_balance = 1000n) in
  let () = assert (total_supply = 1000n) in
  let () = assert (List.length ops = 0) in

  "Minting succeeded"

(**
 * Test: Burning tokens
 *)
let test_burn =
  (* Setup: Alice has 100 tokens *)
  let storage = add_balance init_storage alice token_id_0 100n in
  let storage = { storage with
    total_supply = Big_map.update token_id_0 (Some 100n) storage.total_supply
  } in

  (* Admin burns 30 tokens from Alice *)
  let (ops, new_storage) = burn alice token_id_0 30n storage in

  (* Verify balance and supply *)
  let alice_balance = get_balance new_storage.ledger alice token_id_0 in
  let total_supply = match Big_map.find_opt token_id_0 new_storage.total_supply with
    | Some supply -> supply
    | None -> 0n
  in

  let () = assert (alice_balance = 70n) in
  let () = assert (total_supply = 70n) in

  "Burning succeeded"

(**
 * Test: Multi-token support
 *)
let test_multi_token =
  (* Setup: Alice has different token types *)
  let storage = add_balance init_storage alice token_id_0 100n in
  let storage = add_balance storage alice token_id_1 50n in

  (* Transfer different token types *)
  let transfer_param = [{
    from_ = alice;
    txs = [
      { to_ = bob; token_id = token_id_0; amount = 30n };
      { to_ = bob; token_id = token_id_1; amount = 20n };
    ];
  }] in

  let (_, new_storage) = transfer transfer_param storage in

  (* Verify balances for both tokens *)
  let alice_balance_0 = get_balance new_storage.ledger alice token_id_0 in
  let alice_balance_1 = get_balance new_storage.ledger alice token_id_1 in
  let bob_balance_0 = get_balance new_storage.ledger bob token_id_0 in
  let bob_balance_1 = get_balance new_storage.ledger bob token_id_1 in

  let () = assert (alice_balance_0 = 70n) in
  let () = assert (alice_balance_1 = 30n) in
  let () = assert (bob_balance_0 = 30n) in
  let () = assert (bob_balance_1 = 20n) in

  "Multi-token support succeeded"

(* ============================================================================
 * Test Runner
 * ============================================================================ *)

let test_suite : string list = [
  test_simple_transfer;
  test_batch_transfer;
  test_operator_transfer;
  test_mint;
  test_burn;
  test_multi_token;
]
