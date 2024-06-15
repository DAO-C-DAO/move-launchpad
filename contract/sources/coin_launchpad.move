module launchpad_address::coin_launchpad {
    use std::option::{Self, Option};
    use std::signer;
    use std::string::{Self, String};
    use std::vector;

    use initia_std::fungible_asset::{Self, Metadata};
    use initia_std::event;
    use initia_std::object::{Self, Object, ExtendRef};
    use initia_std::managed_coin;
    use initia_std::coin;
    use initia_std::table::{Self, Table};

    const LAUNCHPAD_SIGNER_SEED: vector<u8> = b"LAUNCHPAD_SIGNER";
    const INIT_COIN_SYMBOL: vector<u8> = b"uinit";
    const DEFAULT_QUERY_LIMIT: u64 = 10;
    const DEFAULT_CREATION_FEE: u64 = 10_000; // 10_000 uinit, aka 0.01 INIT

    /// Coin symbol has been taken, please pick a different symbol
    const ECOIN_SYMBOL_IS_TAKEN: u64 = 1;
    /// Only admin can update admin
    const EONLY_ADMIN_CAN_UPDATE_ADMIN: u64 = 2;
    /// Only admin can update admin
    const EONLY_ADMIN_CAN_UPDATE_FEE_COLLECTOR: u64 = 3;
    /// Only admin can update creation fee
    const EONLY_ADMIN_CAN_UPDATE_CREATION_FEE: u64 = 3;

    #[event]
    struct CreateCoinEvent has store, drop {
        creator_addr: address,
        coin_obj_addr: address,
        maximum_supply: u64,
        name: String,
        symbol: String,
        decimals: u8,
        icon_uri: String,
        project_uri: String,
    }

    struct Registry has key {
        coins: Table<String, Object<Metadata>>
    }

    struct LaunchpadConfig has key {
        admin: address,
        fee_collector: address,
        creation_fee: u64,
        launchpad_obj_extend_ref: ExtendRef,
    }

    fun init_module(sender: &signer) {
        let sender_addr = signer::address_of(sender);

        let launchpad_obj_constructor_ref = &object::create_named_object(sender, LAUNCHPAD_SIGNER_SEED, false);
        let launchpad_obj_signer = &object::generate_signer(launchpad_obj_constructor_ref);
        let launchpad_obj_extend_ref = object::generate_extend_ref(launchpad_obj_constructor_ref);

        move_to(launchpad_obj_signer, LaunchpadConfig {
            admin: sender_addr,
            fee_collector: sender_addr,
            creation_fee: DEFAULT_CREATION_FEE,
            launchpad_obj_extend_ref,
        });
        move_to(launchpad_obj_signer, Registry {
            coins: table::new(),
        });
    }

    // ================================= Entry Functions ================================= //

    public entry fun update_admin(sender: &signer, new_admin: address) acquires LaunchpadConfig {
        let config = borrow_global_mut<LaunchpadConfig>(get_launchpad_signer_addr());
        assert!(config.admin == signer::address_of(sender), EONLY_ADMIN_CAN_UPDATE_ADMIN);
        config.admin = new_admin;
    }

    public entry fun update_fee_collector(sender: &signer, new_fee_collector: address) acquires LaunchpadConfig {
        let config = borrow_global_mut<LaunchpadConfig>(get_launchpad_signer_addr());
        assert!(config.fee_collector == signer::address_of(sender), EONLY_ADMIN_CAN_UPDATE_FEE_COLLECTOR);
        config.fee_collector = new_fee_collector;
    }

    public entry fun update_creation_fee(sender: &signer, new_creation_fee: u64) acquires LaunchpadConfig {
        let config = borrow_global_mut<LaunchpadConfig>(get_launchpad_signer_addr());
        assert!(config.admin == signer::address_of(sender), EONLY_ADMIN_CAN_UPDATE_CREATION_FEE);
        config.creation_fee = new_creation_fee;
    }

    public entry fun create_coin(
        sender: &signer,
        maximum_supply: u64,
        name: String,
        symbol: String,
        decimals: u8,
        icon_uri: String,
        project_uri: String,
    ) acquires Registry, LaunchpadConfig {
        let sender_addr = signer::address_of(sender);
        let launchpad_signer = &get_launchpad_signer();
        let launchpad_signer_addr = get_launchpad_signer_addr();

        managed_coin::initialize(
            launchpad_signer,
            option::some((maximum_supply as u128)),
            name,
            symbol,
            decimals,
            icon_uri,
            project_uri,
        );
        let coin_metadata = coin::metadata(launchpad_signer_addr, symbol);

        let (_, fee_collector, creation_fee) = get_launchpad_config();
        let fee_coin = coin::metadata(@initia_std, string::utf8(INIT_COIN_SYMBOL));
        coin::transfer(sender, fee_collector, fee_coin, creation_fee);

        managed_coin::mint(launchpad_signer, sender_addr, coin_metadata, maximum_supply);

        let registry = borrow_global_mut<Registry>(launchpad_signer_addr);
        assert!(!table::contains(&registry.coins, symbol), ECOIN_SYMBOL_IS_TAKEN);
        table::add(&mut registry.coins, symbol, coin_metadata);

        event::emit(CreateCoinEvent {
            creator_addr: sender_addr,
            coin_obj_addr: object::object_address(coin_metadata),
            maximum_supply,
            name,
            symbol,
            decimals,
            icon_uri,
            project_uri,
        });
    }

    // ================================= View Functions ================================== //

    #[view]
    public fun get_launchpad_config(): (address, address, u64) acquires LaunchpadConfig {
        let launchpad_config = borrow_global<LaunchpadConfig>(get_launchpad_signer_addr());
        (launchpad_config.admin, launchpad_config.fee_collector, launchpad_config.creation_fee)
    }

    #[view]
    public fun get_created_coins(start_after: Option<String>, limit: Option<u64>): vector<Object<Metadata>> acquires Registry {
        let registry = borrow_global<Registry>(get_launchpad_signer_addr());
        let iter = table::iter(&registry.coins, start_after, option::none(), 1);
        let result = vector[];
        for (i in 0.. *option::borrow_with_default(&limit, &DEFAULT_QUERY_LIMIT)) {
            if (!table::prepare(&mut iter)) {
                break
            };
            let (_, coin) = table::next(&mut iter);
            vector::push_back(&mut result, *coin);
        };
        result
    }

    #[view]
    public fun get_coin_data(
        coin_obj: Object<Metadata>
    ): (String, String, u8, Option<u128>, Option<u128>) {
        let current_supply = fungible_asset::supply(coin_obj);
        let max_supply = fungible_asset::maximum(coin_obj);
        (
            fungible_asset::name(coin_obj),
            fungible_asset::symbol(coin_obj),
            fungible_asset::decimals(coin_obj),
            current_supply,
            max_supply,
        )
    }

    // ================================= Helpers ================================== //

    fun get_launchpad_signer_addr(): address {
        object::create_object_address(@launchpad_address, LAUNCHPAD_SIGNER_SEED)
    }

    fun get_launchpad_signer(): signer acquires LaunchpadConfig {
        let launchpad_signer_addr = get_launchpad_signer_addr();
        let launchpad_config = borrow_global<LaunchpadConfig>(launchpad_signer_addr);
        object::generate_signer_for_extending(&launchpad_config.launchpad_obj_extend_ref)
    }

    // ================================= Tests ================================== //

    #[test_only]
    use initia_std::primary_fungible_store;

    #[test(chain = @0x1, sender = @launchpad_address, fee_collector = @0x100, user1 = @0x101)]
    fun test_end_to_end(chain: &signer, sender: &signer, fee_collector: &signer, user1: &signer) acquires Registry, LaunchpadConfig {
        let _chain_addr = signer::address_of(chain);
        let _sender_addr = signer::address_of(sender);
        let fee_collector_addr = signer::address_of(fee_collector);
        let user1_addr = signer::address_of(user1);

        primary_fungible_store::init_module_for_test(chain);
        let (mint_cap, _burn_cap, _freeze_cap) = coin::initialize(
            chain,
            std::option::none(),
            string::utf8(b"INIT Coin"),
            string::utf8(INIT_COIN_SYMBOL),
            6,
            string::utf8(b""),
            string::utf8(b""),
        );
        let init_coin = coin::metadata(@initia_std, string::utf8(INIT_COIN_SYMBOL));

        init_module(sender);
        update_fee_collector(sender, fee_collector_addr);

        // create first coin
        {
            let (_admin_addr, fee_collector_addr, creation_fee) = get_launchpad_config();
            coin::deposit(user1_addr, coin::mint(&mint_cap, creation_fee));

            create_coin(
                user1,
                100_000_000,
                string::utf8(b"GM Coin"),
                string::utf8(b"ugm"),
                6,
                string::utf8(b"gm.initia.icon"),
                string::utf8(b"gm.initia")
            );
            let created_coins = get_created_coins(option::none(), option::none());
            let coin_1 = *vector::borrow(&created_coins, vector::length(&created_coins) - 1);

            let (_name, _symbol, _decimals, current_supply, max_supply) = get_coin_data(coin_1);
            assert!(current_supply == option::some(100_000_000), 1);
            assert!(max_supply == option::some(100_000_000), 2);
            assert!(primary_fungible_store::balance(user1_addr, coin_1) == 100_000_000, 3);
            assert!(primary_fungible_store::balance(user1_addr, init_coin) == 0, 4);
            assert!(primary_fungible_store::balance(fee_collector_addr, init_coin) == DEFAULT_CREATION_FEE, 5);
        };
    }
}
