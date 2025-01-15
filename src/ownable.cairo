use core::starknet::ContractAddress;

#[starknet::interface]
pub trait IOwnable<TContractState> {
    fn owner(self: @TContractState) -> ContractAddress;
    fn is_owner(self: @TContractState) -> bool;
    fn transfer_ownership(ref self: TContractState, address: ContractAddress);
    fn revoke_ownership(ref self: TContractState);
}

/// This component is for access control. 
/// To make sure that only the owner can peforms certain action
#[starknet::component]
pub mod owner_component {
    use core::starknet::{ContractAddress, get_caller_address};
    use core::starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use core::num::traits::Zero;


    #[storage]
    pub struct Storage {
        owner: ContractAddress
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        OwnerTransferred: OwnerTransferred,
        OwnerRevoked: OwnerRevoked
    }

    #[derive(Drop, starknet::Event)]
    struct OwnerTransferred {
        from: ContractAddress,
        to: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct OwnerRevoked {
        owner: ContractAddress,
    }

    #[embeddable_as(Ownable)]
    pub impl OwnableImpl<
        TContractState, +HasComponent<TContractState>
    > of super::IOwnable<ComponentState<TContractState>> {
        fn owner(self: @ComponentState<TContractState>) -> ContractAddress {
            self.owner.read()
        }
        fn is_owner(self: @ComponentState<TContractState>) -> bool {
            self.owner.read() == get_caller_address()
        }
        fn transfer_ownership(ref self: ComponentState<TContractState>, address: ContractAddress) {
            self.assert_is_owner();

            assert!(!address.is_zero(), "Zero address not accepted for transfer");
            let prev_owner = self.owner.read();
            self.owner.write(address);
            self.emit(OwnerTransferred { from: prev_owner, to: address })
        }
        fn revoke_ownership(ref self: ComponentState<TContractState>) {
            self.assert_is_owner();
            self.owner.write(Zero::zero());
            self.emit(OwnerRevoked { owner: get_caller_address() })
        }
    }

    #[generate_trait]
    pub impl Private<
        TContractState, +HasComponent<TContractState>
    > of PrivateTrait<TContractState> {
        fn assert_is_owner(self: @ComponentState<TContractState>) {
            assert!(self.owner.read() == get_caller_address(), "Unauthorized")
        }
        fn initialize_owner(ref self: ComponentState<TContractState>) {
            self.owner.write(get_caller_address())
        }
    }
}
