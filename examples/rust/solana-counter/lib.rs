use anchor_lang::prelude::*;

declare_id!("Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS");

/// Counter program demonstrating Solana/Anchor development
#[program]
pub mod counter_program {
    use super::*;

    /// Initialize a new counter account
    pub fn initialize(ctx: Context<Initialize>) -> Result<()> {
        let counter = &mut ctx.accounts.counter;
        counter.count = 0;
        counter.authority = ctx.accounts.authority.key();
        counter.bump = ctx.bumps.counter;

        msg!("Counter initialized with authority: {}", counter.authority);
        Ok(())
    }

    /// Increment the counter by 1
    pub fn increment(ctx: Context<Update>) -> Result<()> {
        let counter = &mut ctx.accounts.counter;

        require!(
            counter.count < u64::MAX,
            CounterError::Overflow
        );

        counter.count = counter.count.checked_add(1)
            .ok_or(CounterError::Overflow)?;

        msg!("Counter incremented to: {}", counter.count);

        emit!(CounterUpdated {
            counter: ctx.accounts.counter.key(),
            new_value: counter.count,
            timestamp: Clock::get()?.unix_timestamp,
        });

        Ok(())
    }

    /// Decrement the counter by 1
    pub fn decrement(ctx: Context<Update>) -> Result<()> {
        let counter = &mut ctx.accounts.counter;

        require!(
            counter.count > 0,
            CounterError::Underflow
        );

        counter.count = counter.count.checked_sub(1)
            .ok_or(CounterError::Underflow)?;

        msg!("Counter decremented to: {}", counter.count);

        emit!(CounterUpdated {
            counter: ctx.accounts.counter.key(),
            new_value: counter.count,
            timestamp: Clock::get()?.unix_timestamp,
        });

        Ok(())
    }

    /// Reset the counter to 0
    pub fn reset(ctx: Context<Update>) -> Result<()> {
        let counter = &mut ctx.accounts.counter;
        counter.count = 0;

        msg!("Counter reset to: 0");

        emit!(CounterReset {
            counter: ctx.accounts.counter.key(),
            timestamp: Clock::get()?.unix_timestamp,
        });

        Ok(())
    }

    /// Update the authority of the counter
    pub fn update_authority(ctx: Context<UpdateAuthority>, new_authority: Pubkey) -> Result<()> {
        let counter = &mut ctx.accounts.counter;
        let old_authority = counter.authority;

        counter.authority = new_authority;

        msg!("Authority updated from {} to {}", old_authority, new_authority);

        emit!(AuthorityUpdated {
            counter: ctx.accounts.counter.key(),
            old_authority,
            new_authority,
            timestamp: Clock::get()?.unix_timestamp,
        });

        Ok(())
    }
}

/// Account structure for the counter
#[account]
pub struct Counter {
    /// Current count value
    pub count: u64,
    /// Authority that can modify the counter
    pub authority: Pubkey,
    /// Bump seed for PDA
    pub bump: u8,
}

impl Counter {
    /// Space required for the Counter account
    /// 8 (discriminator) + 8 (count) + 32 (authority) + 1 (bump)
    pub const LEN: usize = 8 + 8 + 32 + 1;
}

/// Context for initializing a new counter
#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(
        init,
        payer = authority,
        space = Counter::LEN,
        seeds = [b"counter", authority.key().as_ref()],
        bump
    )]
    pub counter: Account<'info, Counter>,

    #[account(mut)]
    pub authority: Signer<'info>,

    pub system_program: Program<'info, System>,
}

/// Context for updating the counter
#[derive(Accounts)]
pub struct Update<'info> {
    #[account(
        mut,
        seeds = [b"counter", authority.key().as_ref()],
        bump = counter.bump,
        has_one = authority @ CounterError::Unauthorized
    )]
    pub counter: Account<'info, Counter>,

    pub authority: Signer<'info>,
}

/// Context for updating authority
#[derive(Accounts)]
pub struct UpdateAuthority<'info> {
    #[account(
        mut,
        seeds = [b"counter", authority.key().as_ref()],
        bump = counter.bump,
        has_one = authority @ CounterError::Unauthorized
    )]
    pub counter: Account<'info, Counter>,

    pub authority: Signer<'info>,
}

/// Events
#[event]
pub struct CounterUpdated {
    pub counter: Pubkey,
    pub new_value: u64,
    pub timestamp: i64,
}

#[event]
pub struct CounterReset {
    pub counter: Pubkey,
    pub timestamp: i64,
}

#[event]
pub struct AuthorityUpdated {
    pub counter: Pubkey,
    pub old_authority: Pubkey,
    pub new_authority: Pubkey,
    pub timestamp: i64,
}

/// Custom errors
#[error_code]
pub enum CounterError {
    #[msg("Counter overflow: maximum value reached")]
    Overflow,

    #[msg("Counter underflow: cannot decrement below zero")]
    Underflow,

    #[msg("Unauthorized: only the authority can perform this action")]
    Unauthorized,
}
