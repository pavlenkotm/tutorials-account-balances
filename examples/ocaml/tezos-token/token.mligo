(**
 * FA2 Token Contract in CameLIGO (OCaml-like syntax for Tezos)
 *
 * This contract implements the FA2 (TZIP-12) token standard on Tezos blockchain.
 * FA2 is a unified token standard supporting fungible, non-fungible, and multi-asset tokens.
 *
 * Features:
 * - Multi-token support (fungible and non-fungible)
 * - Transfer operations with operator delegation
 * - Balance queries
 * - Metadata support (TZIP-16)
 * - Type-safe functional programming patterns
 *)

(* ============================================================================
 * Type Definitions
 * ============================================================================ *)

type token_id = nat

type transfer_destination = {
  to_       : address;
  token_id  : token_id;
  amount    : nat;
}

type transfer_item = {
  from_ : address;
  txs   : transfer_destination list;
}

type balance_request = {
  owner    : address;
  token_id : token_id;
}

type balance_response = {
  request : balance_request;
  balance : nat;
}

type operator_param = {
  owner    : address;
  operator : address;
  token_id : token_id;
}

type update_operator =
  | Add_operator    of operator_param
  | Remove_operator of operator_param

type token_metadata = {
  token_id   : token_id;
  token_info : (string, bytes) map;
}

(* Contract parameter types *)
type fa2_entry_points =
  | Transfer           of transfer_item list
  | Balance_of         of (balance_request list) * (balance_response list contract)
  | Update_operators   of update_operator list
  | Mint               of address * token_id * nat
  | Burn               of address * token_id * nat

(* Storage types *)
type ledger = ((address * token_id), nat) big_map
type operators = ((address * (address * token_id)), unit) big_map
type token_metadata_storage = (token_id, token_metadata) big_map

type storage = {
  ledger         : ledger;
  operators      : operators;
  token_metadata : token_metadata_storage;
  admin          : address;
  total_supply   : (token_id, nat) big_map;
}

(* ============================================================================
 * Error Codes
 * ============================================================================ *)

let error_NOT_OWNER               = "FA2_NOT_OWNER"
let error_INSUFFICIENT_BALANCE    = "FA2_INSUFFICIENT_BALANCE"
let error_NOT_OPERATOR            = "FA2_NOT_OPERATOR"
let error_TOKEN_UNDEFINED         = "FA2_TOKEN_UNDEFINED"
let error_NOT_ADMIN               = "NOT_ADMIN"

(* ============================================================================
 * Helper Functions
 * ============================================================================ *)

(**
 * Get balance for an address and token_id.
 * Returns 0 if the address has no balance for this token.
 *)
let get_balance (ledger : ledger) (owner : address) (token_id : token_id) : nat =
  match Big_map.find_opt (owner, token_id) ledger with
  | Some balance -> balance
  | None -> 0n

(**
 * Update balance in the ledger.
 * Removes entry if balance becomes 0 (gas optimization).
 *)
let update_balance (ledger : ledger) (owner : address) (token_id : token_id) (new_balance : nat) : ledger =
  if new_balance = 0n then
    Big_map.remove (owner, token_id) ledger
  else
    Big_map.update (owner, token_id) (Some new_balance) ledger

(**
 * Check if an address is an operator for a given owner and token.
 *)
let is_operator (operators : operators) (owner : address) (operator : address) (token_id : token_id) : bool =
  if operator = owner then
    true
  else
    Big_map.mem (owner, (operator, token_id)) operators

(**
 * Validate that sender is either the owner or an approved operator.
 *)
let validate_operator (operators : operators) (owner : address) (token_id : token_id) : unit =
  if not (is_operator operators owner Tezos.sender token_id) then
    failwith error_NOT_OPERATOR
  else
    ()

(**
 * Validate that sender is the contract admin.
 *)
let validate_admin (admin : address) : unit =
  if Tezos.sender <> admin then
    failwith error_NOT_ADMIN
  else
    ()

(* ============================================================================
 * Entry Point Implementations
 * ============================================================================ *)

(**
 * Process a single transfer destination.
 * Implements safe transfer with balance validation.
 *)
let process_transfer_destination
  (ledger : ledger)
  (from_ : address)
  (dest : transfer_destination)
  : ledger =
  let { to_; token_id; amount } = dest in

  (* Get current balances *)
  let from_balance = get_balance ledger from_ token_id in
  let to_balance = get_balance ledger to_ token_id in

  (* Validate sufficient balance *)
  let () = if from_balance < amount then
    failwith error_INSUFFICIENT_BALANCE
  else
    () in

  (* Update balances *)
  let ledger = update_balance ledger from_ token_id (abs (from_balance - amount)) in
  let ledger = update_balance ledger to_ token_id (to_balance + amount) in

  ledger

(**
 * Process a single transfer item (from one sender to multiple recipients).
 *)
let process_transfer_item
  (operators : operators)
  (ledger : ledger)
  (item : transfer_item)
  : ledger =
  let { from_; txs } = item in

  (* Validate each transfer and accumulate ledger updates *)
  let process_tx (acc_ledger : ledger) (dest : transfer_destination) : ledger =
    let () = validate_operator operators from_ dest.token_id in
    process_transfer_destination acc_ledger from_ dest
  in

  List.fold process_tx txs ledger

(**
 * Transfer entry point.
 * Allows batch transfers from multiple senders to multiple recipients.
 *)
let transfer (params : transfer_item list) (storage : storage) : operation list * storage =
  let new_ledger = List.fold (process_transfer_item storage.operators) params storage.ledger in
  (([] : operation list), { storage with ledger = new_ledger })

(**
 * Balance_of entry point.
 * Queries balances and sends response to a callback contract.
 *)
let balance_of
  (requests : balance_request list)
  (callback : balance_response list contract)
  (storage : storage)
  : operation list * storage =
  (* Build response list *)
  let build_response (req : balance_request) : balance_response =
    let { owner; token_id } = req in
    let balance = get_balance storage.ledger owner token_id in
    { request = req; balance = balance }
  in

  let responses = List.map build_response requests in

  (* Send response to callback *)
  let operation = Tezos.transaction responses 0mutez callback in

  ([operation], storage)

(**
 * Update a single operator permission.
 *)
let update_operator (operators : operators) (update : update_operator) : operators =
  match update with
  | Add_operator param ->
      let { owner; operator; token_id } = param in
      let () = if owner <> Tezos.sender then
        failwith error_NOT_OWNER
      else
        () in
      Big_map.update (owner, (operator, token_id)) (Some unit) operators

  | Remove_operator param ->
      let { owner; operator; token_id } = param in
      let () = if owner <> Tezos.sender then
        failwith error_NOT_OWNER
      else
        () in
      Big_map.remove (owner, (operator, token_id)) operators

(**
 * Update_operators entry point.
 * Allows batch addition/removal of operator permissions.
 *)
let update_operators (updates : update_operator list) (storage : storage) : operation list * storage =
  let new_operators = List.fold update_operator updates storage.operators in
  (([] : operation list), { storage with operators = new_operators })

(**
 * Mint entry point (admin only).
 * Creates new tokens and assigns them to a recipient.
 *)
let mint (to_ : address) (token_id : token_id) (amount : nat) (storage : storage) : operation list * storage =
  let () = validate_admin storage.admin in

  (* Update ledger *)
  let current_balance = get_balance storage.ledger to_ token_id in
  let new_ledger = update_balance storage.ledger to_ token_id (current_balance + amount) in

  (* Update total supply *)
  let current_supply = match Big_map.find_opt token_id storage.total_supply with
    | Some supply -> supply
    | None -> 0n
  in
  let new_total_supply = Big_map.update token_id (Some (current_supply + amount)) storage.total_supply in

  (([] : operation list), { storage with
    ledger = new_ledger;
    total_supply = new_total_supply;
  })

(**
 * Burn entry point (admin only).
 * Destroys tokens from a specific address.
 *)
let burn (from_ : address) (token_id : token_id) (amount : nat) (storage : storage) : operation list * storage =
  let () = validate_admin storage.admin in

  (* Validate balance *)
  let current_balance = get_balance storage.ledger from_ token_id in
  let () = if current_balance < amount then
    failwith error_INSUFFICIENT_BALANCE
  else
    () in

  (* Update ledger *)
  let new_ledger = update_balance storage.ledger from_ token_id (abs (current_balance - amount)) in

  (* Update total supply *)
  let current_supply = match Big_map.find_opt token_id storage.total_supply with
    | Some supply -> supply
    | None -> 0n
  in
  let new_total_supply = Big_map.update token_id (Some (abs (current_supply - amount))) storage.total_supply in

  (([] : operation list), { storage with
    ledger = new_ledger;
    total_supply = new_total_supply;
  })

(* ============================================================================
 * Main Entry Point
 * ============================================================================ *)

(**
 * Main function that routes to appropriate entry points.
 * This is the single entry point for the contract.
 *)
let main (action : fa2_entry_points) (storage : storage) : operation list * storage =
  match action with
  | Transfer params ->
      transfer params storage

  | Balance_of (requests, callback) ->
      balance_of requests callback storage

  | Update_operators updates ->
      update_operators updates storage

  | Mint (to_, token_id, amount) ->
      mint to_ token_id amount storage

  | Burn (from_, token_id, amount) ->
      burn from_ token_id amount storage
