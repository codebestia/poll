#[starknet::interface]
trait IPausable<TContractState> {
    fn pause(ref self: TContractState);
    fn unpause(ref self: TContractState);
    fn when_not_paused(self: @TContractState);
    fn is_paused(self: @TContractState) -> bool;
}

#[starknet::component]
pub mod pausable_component {
    use core::starknet::{get_block_timestamp};
    use core::starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use voting::ownable::{owner_component, owner_component::Private};


    #[storage]
    pub struct Storage {
        paused: bool,
    }
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        Paused: Paused,
        UnPaused: UnPaused,
    }
    #[derive(Drop, starknet::Event)]
    struct Paused {
        blocktime: u64
    }
    #[derive(Drop, starknet::Event)]
    struct UnPaused {
        blocktime: u64
    }

    #[embeddable_as(Pausable)]
    pub impl PausableImpl<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl Owner: owner_component::HasComponent<TContractState>
    > of super::IPausable<ComponentState<TContractState>> {
        fn pause(ref self: ComponentState<TContractState>) {
            let owner_comp = get_dep_component!(@self, Owner);
            owner_comp.assert_is_owner();
            self.paused.write(true);
            self.emit(Paused { blocktime: get_block_timestamp() });
        }
        fn unpause(ref self: ComponentState<TContractState>) {
            let owner_comp = get_dep_component!(@self, Owner);
            owner_comp.assert_is_owner();
            self.paused.write(false);
            self.emit(UnPaused { blocktime: get_block_timestamp() });
        }
        fn when_not_paused(self: @ComponentState<TContractState>) {
            assert!(!self.paused.read(), "Contract Paused")
        }
        fn is_paused(self: @ComponentState<TContractState>) -> bool {
            self.paused.read()
        }
    }
}
