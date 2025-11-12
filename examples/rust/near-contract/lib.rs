use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};
use near_sdk::collections::{LookupMap, Vector};
use near_sdk::serde::{Deserialize, Serialize};
use near_sdk::{env, near_bindgen, AccountId, PanicOnDefault};

#[derive(BorshDeserialize, BorshSerialize, Serialize, Deserialize, Clone)]
#[serde(crate = "near_sdk::serde")]
pub struct ActionEntry {
    pub action: String,
    pub value: u64,
    pub timestamp: u64,
    pub account: AccountId,
}

#[near_bindgen]
#[derive(BorshDeserialize, BorshSerialize, PanicOnDefault)]
pub struct Counter {
    counter: u64,
    owner: AccountId,
    total_increments: u64,
    total_decrements: u64,
    user_counts: LookupMap<AccountId, u64>,
    history: Vector<ActionEntry>,
}

#[near_bindgen]
impl Counter {
    /// Initialize the contract with owner and initial value
    #[init]
    pub fn new(owner_id: AccountId, initial_value: u64) -> Self {
        assert!(!env::state_exists(), "Already initialized");
        Self {
            counter: initial_value,
            owner: owner_id,
            total_increments: 0,
            total_decrements: 0,
            user_counts: LookupMap::new(b"u"),
            history: Vector::new(b"h"),
        }
    }

    /// Initialize with default values (counter = 0, owner = predecessor)
    #[init]
    pub fn default() -> Self {
        Self::new(env::predecessor_account_id(), 0)
    }

    // View methods (read-only, no gas for caller)

    /// Get the current counter value
    pub fn get_counter(&self) -> u64 {
        self.counter
    }

    /// Get the contract owner
    pub fn get_owner(&self) -> AccountId {
        self.owner.clone()
    }

    /// Get total number of increments
    pub fn get_total_increments(&self) -> u64 {
        self.total_increments
    }

    /// Get total number of decrements
    pub fn get_total_decrements(&self) -> u64 {
        self.total_decrements
    }

    /// Get action count for a specific account
    pub fn get_user_count(&self, account_id: AccountId) -> u64 {
        self.user_counts.get(&account_id).unwrap_or(0)
    }

    /// Check if account is the owner
    pub fn is_owner(&self, account_id: AccountId) -> bool {
        account_id == self.owner
    }

    /// Get recent history (last N entries)
    pub fn get_history(&self, limit: u64) -> Vec<ActionEntry> {
        let len = self.history.len();
        let start = if len > limit { len - limit } else { 0 };

        (start..len)
            .map(|i| self.history.get(i).unwrap())
            .collect()
    }

    /// Get total number of history entries
    pub fn get_history_length(&self) -> u64 {
        self.history.len()
    }

    /// Get comprehensive statistics
    pub fn get_stats(&self) -> serde_json::Value {
        serde_json::json!({
            "counter": self.counter,
            "total_increments": self.total_increments,
            "total_decrements": self.total_decrements,
            "history_length": self.history.len(),
            "owner": self.owner
        })
    }

    // Change methods (modify state)

    /// Increment the counter by 1
    pub fn increment(&mut self) -> u64 {
        let caller = env::predecessor_account_id();

        self.counter = self.counter.checked_add(1)
            .expect("Counter overflow");

        self.total_increments += 1;
        self.update_user_count(&caller);
        self.add_to_history("increment".to_string(), self.counter, caller);

        env::log_str(&format!("Counter incremented to {}", self.counter));

        self.counter
    }

    /// Decrement the counter by 1
    pub fn decrement(&mut self) -> u64 {
        let caller = env::predecessor_account_id();

        assert!(self.counter > 0, "Counter underflow: cannot decrement below 0");

        self.counter -= 1;
        self.total_decrements += 1;
        self.update_user_count(&caller);
        self.add_to_history("decrement".to_string(), self.counter, caller);

        env::log_str(&format!("Counter decremented to {}", self.counter));

        self.counter
    }

    /// Increment the counter by a specific amount
    pub fn increment_by(&mut self, amount: u64) -> u64 {
        let caller = env::predecessor_account_id();

        self.counter = self.counter.checked_add(amount)
            .expect("Counter overflow");

        self.total_increments += amount;
        self.update_user_count(&caller);
        self.add_to_history(
            format!("increment_by_{}", amount),
            self.counter,
            caller
        );

        env::log_str(&format!("Counter incremented by {} to {}", amount, self.counter));

        self.counter
    }

    /// Reset the counter to 0 (owner only)
    pub fn reset(&mut self) {
        let caller = env::predecessor_account_id();
        self.assert_owner(&caller);

        self.counter = 0;
        self.add_to_history("reset".to_string(), 0, caller);

        env::log_str("Counter reset to 0");
    }

    /// Set the counter to a specific value (owner only)
    pub fn set_counter(&mut self, value: u64) {
        let caller = env::predecessor_account_id();
        self.assert_owner(&caller);

        self.counter = value;
        self.add_to_history(
            format!("set_to_{}", value),
            value,
            caller
        );

        env::log_str(&format!("Counter set to {}", value));
    }

    /// Transfer ownership (owner only)
    pub fn transfer_ownership(&mut self, new_owner: AccountId) {
        let caller = env::predecessor_account_id();
        self.assert_owner(&caller);

        env::log_str(&format!(
            "Ownership transferred from {} to {}",
            self.owner,
            new_owner
        ));

        self.owner = new_owner;
    }

    /// Clear history (owner only)
    pub fn clear_history(&mut self) {
        let caller = env::predecessor_account_id();
        self.assert_owner(&caller);

        self.history.clear();
        env::log_str("History cleared");
    }

    // Private methods

    fn assert_owner(&self, account: &AccountId) {
        assert_eq!(
            account, &self.owner,
            "Only the owner can perform this action"
        );
    }

    fn update_user_count(&mut self, account: &AccountId) {
        let current = self.user_counts.get(account).unwrap_or(0);
        self.user_counts.insert(account, &(current + 1));
    }

    fn add_to_history(&mut self, action: String, value: u64, account: AccountId) {
        let entry = ActionEntry {
            action,
            value,
            timestamp: env::block_timestamp(),
            account,
        };

        self.history.push(&entry);

        // Keep only last 1000 entries to manage storage
        if self.history.len() > 1000 {
            // Remove oldest entry
            for i in 0..self.history.len() - 1 {
                if let Some(entry) = self.history.get(i + 1) {
                    self.history.replace(i, &entry);
                }
            }
            self.history.pop();
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use near_sdk::test_utils::{accounts, VMContextBuilder};
    use near_sdk::testing_env;

    fn get_context(predecessor: AccountId) -> VMContextBuilder {
        let mut builder = VMContextBuilder::new();
        builder.predecessor_account_id(predecessor);
        builder
    }

    #[test]
    fn test_new() {
        let context = get_context(accounts(0));
        testing_env!(context.build());

        let contract = Counter::new(accounts(0), 10);
        assert_eq!(contract.get_counter(), 10);
        assert_eq!(contract.get_owner(), accounts(0));
    }

    #[test]
    fn test_increment() {
        let context = get_context(accounts(0));
        testing_env!(context.build());

        let mut contract = Counter::default();
        assert_eq!(contract.get_counter(), 0);

        contract.increment();
        assert_eq!(contract.get_counter(), 1);
        assert_eq!(contract.get_total_increments(), 1);
    }

    #[test]
    fn test_decrement() {
        let context = get_context(accounts(0));
        testing_env!(context.build());

        let mut contract = Counter::new(accounts(0), 5);

        contract.decrement();
        assert_eq!(contract.get_counter(), 4);
        assert_eq!(contract.get_total_decrements(), 1);
    }

    #[test]
    #[should_panic(expected = "Counter underflow")]
    fn test_decrement_underflow() {
        let context = get_context(accounts(0));
        testing_env!(context.build());

        let mut contract = Counter::default();
        contract.decrement(); // Should panic
    }

    #[test]
    fn test_increment_by() {
        let context = get_context(accounts(0));
        testing_env!(context.build());

        let mut contract = Counter::default();

        contract.increment_by(10);
        assert_eq!(contract.get_counter(), 10);
        assert_eq!(contract.get_total_increments(), 10);
    }

    #[test]
    fn test_reset() {
        let context = get_context(accounts(0));
        testing_env!(context.build());

        let mut contract = Counter::new(accounts(0), 100);

        contract.reset();
        assert_eq!(contract.get_counter(), 0);
    }

    #[test]
    #[should_panic(expected = "Only the owner")]
    fn test_reset_unauthorized() {
        let mut context = get_context(accounts(0));
        testing_env!(context.build());

        let mut contract = Counter::new(accounts(0), 100);

        // Try to reset as different account
        context.predecessor_account_id(accounts(1));
        testing_env!(context.build());

        contract.reset(); // Should panic
    }

    #[test]
    fn test_user_count() {
        let context = get_context(accounts(0));
        testing_env!(context.build());

        let mut contract = Counter::default();

        contract.increment();
        contract.increment();

        assert_eq!(contract.get_user_count(accounts(0)), 2);
    }
}
