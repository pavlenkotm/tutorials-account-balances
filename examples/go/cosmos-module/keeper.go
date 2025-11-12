package counter

import (
	"fmt"

	"github.com/cosmos/cosmos-sdk/codec"
	storetypes "github.com/cosmos/cosmos-sdk/store/types"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/tendermint/tendermint/libs/log"
)

// Keeper maintains the link to data storage and exposes getter/setter methods
type Keeper struct {
	cdc      codec.BinaryCodec
	storeKey storetypes.StoreKey
}

// NewKeeper creates a new counter Keeper instance
func NewKeeper(
	cdc codec.BinaryCodec,
	storeKey storetypes.StoreKey,
) Keeper {
	return Keeper{
		cdc:      cdc,
		storeKey: storeKey,
	}
}

// Logger returns a module-specific logger
func (k Keeper) Logger(ctx sdk.Context) log.Logger {
	return ctx.Logger().With("module", fmt.Sprintf("x/%s", ModuleName))
}

// GetCounter gets the counter value from the store
func (k Keeper) GetCounter(ctx sdk.Context) uint64 {
	store := ctx.KVStore(k.storeKey)
	bz := store.Get(CounterKey)
	if bz == nil {
		return 0
	}

	var counter uint64
	k.cdc.MustUnmarshal(bz, &counter)
	return counter
}

// SetCounter sets the counter value in the store
func (k Keeper) SetCounter(ctx sdk.Context, counter uint64) {
	store := ctx.KVStore(k.storeKey)
	bz := k.cdc.MustMarshal(&counter)
	store.Set(CounterKey, bz)
}

// Increment increments the counter by 1
func (k Keeper) Increment(ctx sdk.Context) (uint64, error) {
	counter := k.GetCounter(ctx)
	counter++
	k.SetCounter(ctx, counter)

	// Emit event
	ctx.EventManager().EmitEvent(
		sdk.NewEvent(
			EventTypeIncrement,
			sdk.NewAttribute(AttributeKeyCounter, fmt.Sprintf("%d", counter)),
			sdk.NewAttribute(AttributeKeyAction, "increment"),
		),
	)

	k.Logger(ctx).Info("Counter incremented", "new_value", counter)
	return counter, nil
}

// Decrement decrements the counter by 1
func (k Keeper) Decrement(ctx sdk.Context) (uint64, error) {
	counter := k.GetCounter(ctx)
	if counter == 0 {
		return 0, fmt.Errorf("counter underflow: cannot decrement below 0")
	}

	counter--
	k.SetCounter(ctx, counter)

	// Emit event
	ctx.EventManager().EmitEvent(
		sdk.NewEvent(
			EventTypeDecrement,
			sdk.NewAttribute(AttributeKeyCounter, fmt.Sprintf("%d", counter)),
			sdk.NewAttribute(AttributeKeyAction, "decrement"),
		),
	)

	k.Logger(ctx).Info("Counter decremented", "new_value", counter)
	return counter, nil
}

// IncrementBy increments the counter by a specific amount
func (k Keeper) IncrementBy(ctx sdk.Context, amount uint64) (uint64, error) {
	if amount == 0 {
		return k.GetCounter(ctx), fmt.Errorf("amount must be greater than 0")
	}

	counter := k.GetCounter(ctx)
	counter += amount
	k.SetCounter(ctx, counter)

	// Emit event
	ctx.EventManager().EmitEvent(
		sdk.NewEvent(
			EventTypeIncrementBy,
			sdk.NewAttribute(AttributeKeyCounter, fmt.Sprintf("%d", counter)),
			sdk.NewAttribute(AttributeKeyAmount, fmt.Sprintf("%d", amount)),
		),
	)

	k.Logger(ctx).Info("Counter incremented by amount", "amount", amount, "new_value", counter)
	return counter, nil
}

// Reset resets the counter to 0
func (k Keeper) Reset(ctx sdk.Context) error {
	k.SetCounter(ctx, 0)

	// Emit event
	ctx.EventManager().EmitEvent(
		sdk.NewEvent(
			EventTypeReset,
			sdk.NewAttribute(AttributeKeyCounter, "0"),
		),
	)

	k.Logger(ctx).Info("Counter reset to 0")
	return nil
}

// SetCounterValue sets the counter to a specific value
func (k Keeper) SetCounterValue(ctx sdk.Context, value uint64) error {
	k.SetCounter(ctx, value)

	// Emit event
	ctx.EventManager().EmitEvent(
		sdk.NewEvent(
			EventTypeSet,
			sdk.NewAttribute(AttributeKeyCounter, fmt.Sprintf("%d", value)),
		),
	)

	k.Logger(ctx).Info("Counter set to value", "value", value)
	return nil
}

// GetStats returns comprehensive statistics
func (k Keeper) GetStats(ctx sdk.Context) Stats {
	return Stats{
		Counter:     k.GetCounter(ctx),
		BlockHeight: ctx.BlockHeight(),
		BlockTime:   ctx.BlockTime(),
	}
}
