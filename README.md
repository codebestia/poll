# Poll

A simple, secure, and decentralized voting system implemented on StarkNet using Cairo. This contract allows for basic campain creation and voting functionality while maintaining voter privacy and preventing double voting.

## Features

- Create and manage multiple voting proposals
- Real-time vote counting
- View proposal status and results
- Ending voting campaign
- Support for both yes/no votes and multiple choice options

## Contract Structure

The main contract consists of the following components:

```cairo
#[starknet::contract]
mod Poll {
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
}
```

## Getting Started

### Prerequisites

- [Cairo 2.2.0](https://cairo-lang.org/docs/quickstart.html) or later
- [Scarb](https://docs.swmansion.com/scarb/)
- [StarkNet CLI](https://www.cairo-lang.org/docs/hello_starknet/cli.html)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/your-username/starknet-voting
cd starknet-voting
```

2. Install dependencies:
```bash
scarb install
```

### Compilation

```bash
scarb build
```


## Usage

### Contract Deployment

1. Deploy the contract to StarkNet:
```bash
npm install
npm run deploy
```

2. Save the deployed contract address for future interactions.

### Creating a Campaign

```cairo
// Function signature
fn create_campaign(ref self: ContractState, name: felt252, options: Array<felt252>) -> u256;
```

### Casting a Vote

```cairo
// Function signature
fn vote(ref self: TContractState, campaign_id: u256, choice: felt252) -> bool;
```

### Viewing Results

```cairo
// Function signature
fn calculate_vote(ref self: TContractState, campaign_id: u256) -> Array<Voted>;
```

## Contract Interface

### Main Functions

- `create_campaign`: Creates a new voting campaign
- `vote`: Allows an address to cast their vote
- `close_campaign`: Allow campaign owner to close campaign
- `pause`: Allows contract owner to pause the contract
- `unpause`: Allows contract owner to pause the contract
- `calculate_vote`: Allows calculation of vote for campaign

### Events

```cairo
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
```

## Security Considerations

- The contract prevent multiple voting
- The contract to change calculate vote to a view function
- Voting deadlines are enforced at the contract level
- Front-running protection mechanisms are in place
- Integer overflow checks are implemented for vote counting

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.
