package counter

import (
	"time"
)

const (
	// ModuleName defines the module name
	ModuleName = "counter"

	// StoreKey defines the primary module store key
	StoreKey = ModuleName

	// RouterKey defines the module's message routing key
	RouterKey = ModuleName

	// QuerierRoute defines the module's query routing key
	QuerierRoute = ModuleName
)

// Store keys
var (
	// CounterKey is the key for storing the counter value
	CounterKey = []byte{0x01}
)

// Event types
const (
	EventTypeIncrement   = "increment_counter"
	EventTypeDecrement   = "decrement_counter"
	EventTypeIncrementBy = "increment_counter_by"
	EventTypeReset       = "reset_counter"
	EventTypeSet         = "set_counter"

	AttributeKeyCounter = "counter_value"
	AttributeKeyAmount  = "amount"
	AttributeKeyAction  = "action"
)

// Stats represents counter statistics
type Stats struct {
	Counter     uint64    `json:"counter"`
	BlockHeight int64     `json:"block_height"`
	BlockTime   time.Time `json:"block_time"`
}

// QueryCounterResponse is the response type for counter queries
type QueryCounterResponse struct {
	Counter uint64 `json:"counter"`
}

// QueryStatsResponse is the response type for stats queries
type QueryStatsResponse struct {
	Stats Stats `json:"stats"`
}
