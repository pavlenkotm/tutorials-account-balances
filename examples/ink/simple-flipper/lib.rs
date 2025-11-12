#![cfg_attr(not(feature = "std"), no_std, no_main)]

#[ink::contract]
mod flipper {
    use ink::storage::Mapping;

    /// The flipper smart contract with access control
    #[ink(storage)]
    pub struct Flipper {
        /// The current value of the flipper
        value: bool,
        /// Mapping from accounts to their flip count
        flip_counts: Mapping<AccountId, u32>,
        /// Total number of flips
        total_flips: u64,
        /// Contract owner
        owner: AccountId,
    }

    /// Event emitted when value is flipped
    #[ink(event)]
    pub struct Flipped {
        #[ink(topic)]
        by: AccountId,
        new_value: bool,
        flip_count: u32,
    }

    /// Event emitted when flipper is reset
    #[ink(event)]
    pub struct Reset {
        #[ink(topic)]
        by: AccountId,
    }

    /// Errors that can occur
    #[derive(Debug, PartialEq, Eq, scale::Encode, scale::Decode)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
    pub enum Error {
        /// Caller is not the owner
        NotOwner,
    }

    pub type Result<T> = core::result::Result<T, Error>;

    impl Flipper {
        /// Constructor that initializes the flipper with the given value
        #[ink(constructor)]
        pub fn new(init_value: bool) -> Self {
            let caller = Self::env().caller();
            Self {
                value: init_value,
                flip_counts: Mapping::default(),
                total_flips: 0,
                owner: caller,
            }
        }

        /// Constructor that initializes the flipper with default value (false)
        #[ink(constructor)]
        pub fn default() -> Self {
            Self::new(false)
        }

        /// Flip the current value of the flipper
        #[ink(message)]
        pub fn flip(&mut self) {
            let caller = self.env().caller();

            // Update value
            self.value = !self.value;

            // Update flip count for caller
            let current_count = self.flip_counts.get(&caller).unwrap_or(0);
            let new_count = current_count + 1;
            self.flip_counts.insert(&caller, &new_count);

            // Update total flips
            self.total_flips += 1;

            // Emit event
            self.env().emit_event(Flipped {
                by: caller,
                new_value: self.value,
                flip_count: new_count,
            });
        }

        /// Get the current value of the flipper
        #[ink(message)]
        pub fn get(&self) -> bool {
            self.value
        }

        /// Get flip count for a specific account
        #[ink(message)]
        pub fn get_flip_count(&self, account: AccountId) -> u32 {
            self.flip_counts.get(&account).unwrap_or(0)
        }

        /// Get total number of flips
        #[ink(message)]
        pub fn get_total_flips(&self) -> u64 {
            self.total_flips
        }

        /// Get the owner of the contract
        #[ink(message)]
        pub fn get_owner(&self) -> AccountId {
            self.owner
        }

        /// Reset the flipper to false (owner only)
        #[ink(message)]
        pub fn reset(&mut self) -> Result<()> {
            let caller = self.env().caller();

            if caller != self.owner {
                return Err(Error::NotOwner);
            }

            self.value = false;

            self.env().emit_event(Reset { by: caller });

            Ok(())
        }

        /// Transfer ownership (owner only)
        #[ink(message)]
        pub fn transfer_ownership(&mut self, new_owner: AccountId) -> Result<()> {
            let caller = self.env().caller();

            if caller != self.owner {
                return Err(Error::NotOwner);
            }

            self.owner = new_owner;

            Ok(())
        }
    }

    #[cfg(test)]
    mod tests {
        use super::*;

        #[ink::test]
        fn default_works() {
            let flipper = Flipper::default();
            assert_eq!(flipper.get(), false);
        }

        #[ink::test]
        fn new_works() {
            let flipper = Flipper::new(true);
            assert_eq!(flipper.get(), true);
        }

        #[ink::test]
        fn flip_works() {
            let mut flipper = Flipper::default();
            assert_eq!(flipper.get(), false);

            flipper.flip();
            assert_eq!(flipper.get(), true);

            flipper.flip();
            assert_eq!(flipper.get(), false);
        }

        #[ink::test]
        fn flip_count_works() {
            let mut flipper = Flipper::default();
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();

            assert_eq!(flipper.get_flip_count(accounts.alice), 0);

            flipper.flip();
            assert_eq!(flipper.get_flip_count(accounts.alice), 1);

            flipper.flip();
            assert_eq!(flipper.get_flip_count(accounts.alice), 2);
        }

        #[ink::test]
        fn total_flips_works() {
            let mut flipper = Flipper::default();
            assert_eq!(flipper.get_total_flips(), 0);

            flipper.flip();
            assert_eq!(flipper.get_total_flips(), 1);

            flipper.flip();
            assert_eq!(flipper.get_total_flips(), 2);
        }

        #[ink::test]
        fn reset_works() {
            let mut flipper = Flipper::new(true);
            assert_eq!(flipper.get(), true);

            let result = flipper.reset();
            assert!(result.is_ok());
            assert_eq!(flipper.get(), false);
        }

        #[ink::test]
        fn reset_fails_for_non_owner() {
            let mut flipper = Flipper::default();
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();

            // Change caller to Bob
            ink::env::test::set_caller::<ink::env::DefaultEnvironment>(accounts.bob);

            let result = flipper.reset();
            assert_eq!(result, Err(Error::NotOwner));
        }

        #[ink::test]
        fn transfer_ownership_works() {
            let mut flipper = Flipper::default();
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();

            assert_eq!(flipper.get_owner(), accounts.alice);

            let result = flipper.transfer_ownership(accounts.bob);
            assert!(result.is_ok());
            assert_eq!(flipper.get_owner(), accounts.bob);
        }
    }
}
