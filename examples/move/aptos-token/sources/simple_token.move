module aptos_token::simple_token {
    use std::signer;
    use std::string::{String};
    use aptos_framework::coin::{Self, Coin, BurnCapability, FreezeCapability, MintCapability};
    use aptos_framework::event;

    /// Error codes
    const E_NOT_ADMIN: u64 = 1;
    const E_INSUFFICIENT_BALANCE: u64 = 2;
    const E_ALREADY_INITIALIZED: u64 = 3;
    const E_NOT_INITIALIZED: u64 = 4;

    /// Token metadata structure
    struct SimpleToken has key {}

    /// Token capabilities stored in module admin account
    struct Capabilities has key {
        mint_cap: MintCapability<SimpleToken>,
        burn_cap: BurnCapability<SimpleToken>,
        freeze_cap: FreezeCapability<SimpleToken>,
    }

    /// Token info stored in module admin account
    struct TokenInfo has key {
        name: String,
        symbol: String,
        decimals: u8,
        total_supply: u64,
    }

    /// Events
    #[event]
    struct TokenMinted has drop, store {
        recipient: address,
        amount: u64,
        timestamp: u64,
    }

    #[event]
    struct TokenBurned has drop, store {
        account: address,
        amount: u64,
        timestamp: u64,
    }

    #[event]
    struct TokenTransferred has drop, store {
        from: address,
        to: address,
        amount: u64,
        timestamp: u64,
    }

    /// Initialize the token module
    /// Can only be called once by the module publisher
    public entry fun initialize(
        admin: &signer,
        name: String,
        symbol: String,
        decimals: u8,
    ) {
        let admin_addr = signer::address_of(admin);

        // Ensure not already initialized
        assert!(!exists<Capabilities>(admin_addr), E_ALREADY_INITIALIZED);
        assert!(!exists<TokenInfo>(admin_addr), E_ALREADY_INITIALIZED);

        // Initialize the token with coin framework
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<SimpleToken>(
            admin,
            name,
            symbol,
            decimals,
            true, // monitor_supply
        );

        // Store capabilities
        move_to(admin, Capabilities {
            mint_cap,
            burn_cap,
            freeze_cap,
        });

        // Store token info
        move_to(admin, TokenInfo {
            name,
            symbol,
            decimals,
            total_supply: 0,
        });
    }

    /// Register an account to receive tokens
    public entry fun register(account: &signer) {
        coin::register<SimpleToken>(account);
    }

    /// Mint new tokens to a recipient
    /// Can only be called by the admin
    public entry fun mint(
        admin: &signer,
        recipient: address,
        amount: u64,
    ) acquires Capabilities, TokenInfo {
        let admin_addr = signer::address_of(admin);
        assert!(exists<Capabilities>(admin_addr), E_NOT_INITIALIZED);

        let capabilities = borrow_global<Capabilities>(admin_addr);
        let token_info = borrow_global_mut<TokenInfo>(admin_addr);

        // Mint tokens
        let coins = coin::mint<SimpleToken>(amount, &capabilities.mint_cap);

        // Deposit to recipient
        coin::deposit<SimpleToken>(recipient, coins);

        // Update total supply
        token_info.total_supply = token_info.total_supply + amount;

        // Emit event
        event::emit(TokenMinted {
            recipient,
            amount,
            timestamp: aptos_framework::timestamp::now_seconds(),
        });
    }

    /// Burn tokens from the caller's account
    public entry fun burn(
        account: &signer,
        amount: u64,
    ) acquires Capabilities, TokenInfo {
        let account_addr = signer::address_of(account);

        // Find admin address (assuming it's stored in the module)
        // In production, you'd store this properly
        let admin_addr = @aptos_token;
        assert!(exists<Capabilities>(admin_addr), E_NOT_INITIALIZED);

        let capabilities = borrow_global<Capabilities>(admin_addr);
        let token_info = borrow_global_mut<TokenInfo>(admin_addr);

        // Withdraw and burn tokens
        let coins = coin::withdraw<SimpleToken>(account, amount);
        coin::burn<SimpleToken>(coins, &capabilities.burn_cap);

        // Update total supply
        token_info.total_supply = token_info.total_supply - amount;

        // Emit event
        event::emit(TokenBurned {
            account: account_addr,
            amount,
            timestamp: aptos_framework::timestamp::now_seconds(),
        });
    }

    /// Transfer tokens from sender to recipient
    public entry fun transfer(
        sender: &signer,
        recipient: address,
        amount: u64,
    ) {
        let sender_addr = signer::address_of(sender);
        coin::transfer<SimpleToken>(sender, recipient, amount);

        // Emit event
        event::emit(TokenTransferred {
            from: sender_addr,
            to: recipient,
            amount,
            timestamp: aptos_framework::timestamp::now_seconds(),
        });
    }

    /// Get balance of an account
    #[view]
    public fun balance_of(account: address): u64 {
        coin::balance<SimpleToken>(account)
    }

    /// Get total supply
    #[view]
    public fun total_supply(): u64 acquires TokenInfo {
        let admin_addr = @aptos_token;
        if (!exists<TokenInfo>(admin_addr)) {
            return 0
        };
        borrow_global<TokenInfo>(admin_addr).total_supply
    }

    /// Get token name
    #[view]
    public fun name(): String acquires TokenInfo {
        let admin_addr = @aptos_token;
        assert!(exists<TokenInfo>(admin_addr), E_NOT_INITIALIZED);
        *&borrow_global<TokenInfo>(admin_addr).name
    }

    /// Get token symbol
    #[view]
    public fun symbol(): String acquires TokenInfo {
        let admin_addr = @aptos_token;
        assert!(exists<TokenInfo>(admin_addr), E_NOT_INITIALIZED);
        *&borrow_global<TokenInfo>(admin_addr).symbol
    }

    /// Get token decimals
    #[view]
    public fun decimals(): u8 acquires TokenInfo {
        let admin_addr = @aptos_token;
        assert!(exists<TokenInfo>(admin_addr), E_NOT_INITIALIZED);
        borrow_global<TokenInfo>(admin_addr).decimals
    }

    #[test_only]
    use aptos_framework::account;

    #[test(admin = @aptos_token)]
    fun test_initialize(admin: &signer) {
        // Setup
        let admin_addr = signer::address_of(admin);
        account::create_account_for_test(admin_addr);

        // Initialize token
        initialize(
            admin,
            b"Simple Token".to_string(),
            b"STK".to_string(),
            8,
        );

        // Verify initialization
        assert!(exists<Capabilities>(admin_addr), 0);
        assert!(exists<TokenInfo>(admin_addr), 0);
    }

    #[test(admin = @aptos_token, user = @0x123)]
    fun test_mint_and_transfer(admin: &signer, user: &signer) acquires Capabilities, TokenInfo {
        // Setup
        let admin_addr = signer::address_of(admin);
        let user_addr = signer::address_of(user);

        account::create_account_for_test(admin_addr);
        account::create_account_for_test(user_addr);

        // Initialize
        initialize(admin, b"Simple Token".to_string(), b"STK".to_string(), 8);

        // Register user
        register(user);

        // Mint to user
        mint(admin, user_addr, 1000);

        // Verify balance
        assert!(balance_of(user_addr) == 1000, 0);
        assert!(total_supply() == 1000, 1);
    }
}
