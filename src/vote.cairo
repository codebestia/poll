#[derive(Drop, Serde)]
struct Voted {
    name: felt252,
    number_of_votes: u128
}

#[starknet::interface]
trait IVote<TContractState> {
    fn create_campaign(ref self: TContractState, name: felt252, options: Array<felt252>) -> u256;
    fn vote(ref self: TContractState, campaign_id: u256, choice: felt252) -> bool;
    fn calculate_vote(ref self: TContractState, campaign_id: u256) -> Array<Voted>;
    fn close_campaign(ref self: TContractState, campaign_id: u256);
}

#[starknet::contract]
mod Poll {
    use super::Voted;
    use starknet::event::EventEmitter;
    use core::starknet::{ContractAddress, get_caller_address};
    use core::starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map, Vec, VecTrait,
        MutableVecTrait
    };
    use voting::{ownable::owner_component, pausable::pausable_component};

    component!(path: owner_component, storage: ownable, event: OwnableEvent);
    component!(path: pausable_component, storage: pausable, event: PausableEvent);

    #[abi(embed_v0)]
    impl Ownable = owner_component::Ownable<ContractState>;

    impl OwnablePrivate = owner_component::Private<ContractState>;

    #[abi(embed_v0)]
    impl Pausable = pausable_component::Pausable<ContractState>;


    #[storage]
    struct Storage {
        campaignData: Map<u256, Campaign>,
        campaignPointer: u256,
        #[substorage(v0)]
        ownable: owner_component::Storage,
        #[substorage(v0)]
        pausable: pausable_component::Storage,
    }

    #[starknet::storage_node]
    struct Campaign {
        id: u256,
        name: felt252,
        owner: ContractAddress,
        options: Vec<felt252>,
        is_closed: bool,
        votes: Map<felt252, u128>
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        UserVotedEvent: UserVotedEvent,
        CampaignCreated: CampaignCreated,
        OwnableEvent: owner_component::Event,
        PausableEvent: pausable_component::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct UserVotedEvent {
        user: ContractAddress,
        #[key]
        campaign: u256
    }

    #[derive(Drop, starknet::Event)]
    struct CampaignCreated {
        #[key]
        owner: ContractAddress,
        campaign: u256
    }

    #[derive(Drop, Serde, Copy, starknet::Store)]
    enum Errors {
        INVALID_POLL,
        CANNOT_VOTE
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.ownable.initialize_owner();
    }

    #[abi(embed_v0)]
    impl Vote of super::IVote<ContractState> {
        fn create_campaign(
            ref self: ContractState, name: felt252, options: Array<felt252>
        ) -> u256 {
            self.pausable.when_not_paused();
            let caller = get_caller_address();
            let index = self.campaignPointer.read() + 1;
            let mut campaign = self.campaignData.entry(index);
            campaign.name.write(name);
            campaign.id.write(index);
            campaign.owner.write(caller);
            campaign.is_closed.write(false);
            for idx in 0..options.len() {
                campaign.options.append().write(*options.at(idx));
            };
            self.campaignPointer.write(index);
            index
        }
        fn vote(ref self: ContractState, campaign_id: u256, choice: felt252) -> bool {
            self.pausable.when_not_paused();
            let caller = get_caller_address();
            if campaign_id > self.campaignPointer.read() {
                panic!("Campaign does not exist");
            }
            let mut campaign = self.campaignData.entry(campaign_id);
            assert!(!campaign.is_closed.read(), "Poll is closed");
            assert!(self.check_option(campaign_id, choice), "Option not available");

            campaign.votes.entry(choice).write(campaign.votes.entry(choice).read() + 1);
            self.emit(UserVotedEvent { user: caller, campaign: campaign_id });
            true
        }
        fn calculate_vote(ref self: ContractState, campaign_id: u256) -> Array<Voted> {
            self.pausable.when_not_paused();
            let mut votes: Array<Voted> = array![];
            let mut campaign = self.campaignData.entry(campaign_id);
            for idx in 0
                ..campaign
                    .options
                    .len() {
                        let choice = campaign.options.at(idx).read();
                        votes
                            .append(
                                Voted {
                                    name: choice,
                                    number_of_votes: campaign.votes.entry(choice).read()
                                }
                            )
                    };
            votes
        }
        fn close_campaign(ref self: ContractState, campaign_id: u256) {
            let caller = get_caller_address();
            if campaign_id > self.campaignPointer.read() {
                panic!("Campaign does not exist");
            }
            let mut campaign = self.campaignData.entry(campaign_id);
            assert!(caller != campaign.owner.read(), "Unauthorized");
            campaign.is_closed.write(true);
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn check_option(self: @ContractState, campaign_id: u256, option_to_check: felt252) -> bool {
            let mut bool_checker = false;
            let campaign = self.campaignData.entry(campaign_id);

            for idx in 0
                ..campaign
                    .options
                    .len() {
                        if campaign.options.at(idx).read() == option_to_check {
                            bool_checker = true;
                            break;
                        }
                    };
            bool_checker
        }
    }
}
