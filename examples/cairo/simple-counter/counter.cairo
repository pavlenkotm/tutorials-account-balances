#[starknet::contract]
mod SimpleCounter {
    use starknet::ContractAddress;
    use starknet::get_caller_address;

    #[storage]
    struct Storage {
        counter: u128,
        owner: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CounterIncremented: CounterIncremented,
        CounterDecremented: CounterDecremented,
        CounterReset: CounterReset,
    }

    #[derive(Drop, starknet::Event)]
    struct CounterIncremented {
        #[key]
        caller: ContractAddress,
        new_value: u128,
    }

    #[derive(Drop, starknet::Event)]
    struct CounterDecremented {
        #[key]
        caller: ContractAddress,
        new_value: u128,
    }

    #[derive(Drop, starknet::Event)]
    struct CounterReset {
        #[key]
        caller: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, initial_value: u128) {
        self.counter.write(initial_value);
        self.owner.write(get_caller_address());
    }

    #[abi(embed_v0)]
    impl SimpleCounterImpl of super::ISimpleCounter<ContractState> {
        fn get_counter(self: @ContractState) -> u128 {
            self.counter.read()
        }

        fn increment(ref self: ContractState) {
            let current = self.counter.read();
            let new_value = current + 1;
            self.counter.write(new_value);

            self.emit(CounterIncremented {
                caller: get_caller_address(),
                new_value: new_value,
            });
        }

        fn decrement(ref self: ContractState) {
            let current = self.counter.read();
            assert(current > 0, 'Counter cannot be negative');
            let new_value = current - 1;
            self.counter.write(new_value);

            self.emit(CounterDecremented {
                caller: get_caller_address(),
                new_value: new_value,
            });
        }

        fn reset(ref self: ContractState) {
            let caller = get_caller_address();
            let owner = self.owner.read();
            assert(caller == owner, 'Only owner can reset');

            self.counter.write(0);
            self.emit(CounterReset { caller: caller });
        }

        fn get_owner(self: @ContractState) -> ContractAddress {
            self.owner.read()
        }
    }
}

#[starknet::interface]
trait ISimpleCounter<TContractState> {
    fn get_counter(self: @TContractState) -> u128;
    fn increment(ref self: TContractState);
    fn decrement(ref self: TContractState);
    fn reset(ref self: TContractState);
    fn get_owner(self: @TContractState) -> ContractAddress;
}
