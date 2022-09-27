module wav3::NFT {

    use std::error;
    use std::signer;
    use std::string::{Self, String};
    use std::vector;
    use std::option::{Self, Option};

    use aptos_framework::block;
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::account;
    use aptos_framework::timestamp;
    use aptos_std::table::{Self, Table};
    use aptos_token::property_map::{Self, PropertyMap};
    use aptos_token::token;

    const ECOLLECTION_ALREADY_EXISTS: u64 = 1;
    const EIMAGE_URI_TOO_LONG: u64 = 2;
    const EANIMATION_URI_TOO_LONG: u64 = 3;
    const EWEBSITE_URI_TOO_LONG: u64 = 4;
    const ETOKEN_DATA_ALREADY_EXISTS: u64 = 5;
    const ECOLLECTION_NOT_PUBLISHED: u64 = 6;
    const ENOT_A_MULTI_EDITION: u64 = 7;
    const ESOCIAL_MEDIA_ALREADY_REGISTER: u64 = 8;
    const ESOCIAL_MEDIA_NOT_REGISTER: u64 = 9;

    struct CollectionExtend has store {
        social_media: SimpleMap<String, String>,
        symbol: string,
        image_uri: string,
        animation_uri: string,
        website: string,
        standard_version: u64,
        commercial_standard: string,
        update_block_height: u64,
        royalty_policy: string,
        multi_edtion: bool
    }

    struct TokenDataExtend has store {
        image_uri: String,
        animation_uri: String,
        image_checksum: u64,
        mutability_config: MutabilityConfig,
        update_block_height: u64
    }

    struct MutabilityConfig has copy, drop, store {
        image_uri: bool
    }

    /// Represent collection and token metadata for a creator
    struct Collections has key {
        collection_extend_data: Table<String, CollectionExtend>,
        token_extend_data: Table<TokenDataId, TokenDataExtend>
    }

    public fun create_collection(        
        creator: &signer,
        name: String,
        description: String,
        maximum: u64,
        mutate_setting: vector<bool>,
        symbol: String,
        image_uri: String,
        animation_uri: String,
        website: String,
        standard_version: u64,
        commercial_standard: string,
        update_block_height: u64,
        royalty_policy: string,
        multi_edtion: bool
    ) acquires Collections {
        let account_addr = signer::address_of(creator);
        if (!exists<Collections>(account_addr)) {
            move_to(
                creator,
                Collections{
                    collection_extend_data: table::new(),
                    token_extend_data: table::new(),
                },
            )
        };
        let collection_extend_data = &mut borrow_global_mut<Collections>(account_addr).collection_extend_data;
        assert!(
            !table::contains(collection_extend_data, name),
            error::already_exists(ECOLLECTION_ALREADY_EXISTS),
        );

        let uri = get_collection_uri(account_addr, collection);
        token::create_collection(creator, name, description, uri, maximum, mutate_setting);

        assert!(string::length(&image_uri) <= MAX_URI_LENGTH, error::invalid_argument(EIMAGE_URI_TOO_LONG));
        assert!(string::length(&animation_url) <= MAX_URI_LENGTH, error::invalid_argument(EANIMATION_URI_TOO_LONG));
        assert!(string::length(&website) <= MAX_URI_LENGTH, error::invalid_argument(EWEBSITE_URI_TOO_LONG));

        table::add(collection_extend_data, name, CollectionExtend {
            social_media: simple_map::create<String, String>(),
            symbol,
            image_uri,
            animationri,
            website,
            standard_version,
            commercial_standard,
            update_block_height,
            royalty_policy,
            multi_edtion
        });
    }

    public fun create_tokendata(
        account: &signer,
        collection: String,
        name: String,
        description: String,
        maximum: u64,
        royalty_payee_address: address,
        royalty_points_denominator: u64,
        royalty_points_numerator: u64,
        token_mutate_config: TokenMutabilityConfig,
        property_keys: vector<String>,
        property_values: vector<vector<u8>>,
        property_types: vector<String>,
        image_uri: String,
        animation_uri: String,
        image_checksum: u64,
        mutability_config: MutabilityConfig,
        update_block_height: u64
    ) acquires Collections {
        let account_addr = signer::address_of(account);
        assert!(
            exists<Collections>(account_addr),
            error::not_found(ECOLLECTIONS_NOT_PUBLISHED),
        );
        let uri = get_token_uri(account_addr, collection, name);
        let token_data_id = token::create_tokendata(
            account,
            collection,
            name,
            description,
            maximum,
            uri,
            royalty_payee_address,
            royalty_points_denominator,
            royalty_points_numerator,
            token_mutate_config,
            property_keys,
            property_values,
            property_types,
        );
        let collections = borrow_global_mut<Collections>(account_addr);
        assert!(string::length(&image_uri) <= MAX_URI_LENGTH, error::invalid_argument(EIMAGE_URI_TOO_LONG));
        assert!(string::length(&animation_url) <= MAX_URI_LENGTH, error::invalid_argument(EANIMATION_URI_TOO_LONG));
        assert!(
            table::contains(&collections.collection_extend_data, name),
            error::already_exists(ECOLLECTION_NOT_PUBLISHED),
        );
        assert!(
            !table::contains(&collections.token_extend_data, token_data_id),
            error::already_exists(ETOKEN_DATA_ALREADY_EXISTS),
        );

        table::add(&mut collections.token_extend_data, token_data_id, TokenDataExtend {
            image_uri,
            animation_uri,
            image_checksum,
            mutability_config,
            update_block_height: block::get_current_block_height() 
        });
    }

    public fun mint_nft(
        account: &signer,
        collection_name: String,
        token_name: String,
        properties: String
    ) acquires Collections {
        let addr = signer::address_of(account);
        let token_data_id = token::create_token_data_id(addr, collection_name, token_name);
        let collections = borrow_global<Collections>(addr);
        let collection_extend_data = table::borrow(collections.collection_extend_data, collection_name);
        if (!collection_extend_data.multi_edtion) {
            let cur_supply =token::get_token_supply(addr, token_data_id);
            assert!(cur_supply <= 1, ENOT_A_MULTI_EDITION);
        };
        let token_id = token::mint_token(account, token_data_id, 1);
        let keys = vector[b"properties"]; 
        let values = vector[*string::bytes(&properties)];
        let types = vector[b"string"];
        let token_id = mutate_one_token(
            account,
            addr,
            token_id,
            keys,
            values,
            types
        );
    }

    public fun add_social_media(
        account: &signer,
        collection: String,
        social_media_type: String,
        social_media: String
    ) acquires Collections {
        let addr = signer::address_of(account);
        let collections = borrow_global_mut<Collections>(addr);
        let collection_extend_data = table::borrow_mut(
            collections.collection_extend_data, collection
        );
        assert!(
            !simple_map::contains_key(&collection_extend_data.social_media, &social_media_type),
            ESOCIAL_MEDIA_ALREADY_REGISTER
        );
        simple_map::add(&mut collection_extend_data.social_media, social_media_type, social_media);
    }

    //TODO: updat social media 
    public fun update_social_media(
        account: &signer,
        collection: String,
        social_media_type: String,
        social_media: String
    ) acquires Collections {
        let addr = signer::address_of(account);
        let collections = borrow_global_mut<Collections>(addr);
        let collection_extend_data = table::borrow_mut(
            collections.collection_extend_data, collection
        );
        assert!(
            simple_map::contains_key(&collection_extend_data.social_media, &social_media_type),
            ESOCIAL_MEDIA_NOT_REGISTER
        );
        let social_meida_ref = simple_map::borrow_mut(&mut collection_extend_data.social_media, social_media_type);
        *social_meida_ref = social_media;
    }

    fun get_collection_uri(creator: address, collection: String): String {
        let addr_vec_out = to_bytes(&creator);
        let addr_string = from_bcs::to_string(addr_vec_out);
        let uri = string::utf8(b"nft://");
        string::append(&mut uri, addr_string);
        string::append(&mut uri, string::utf8(b"/"));
        string::append(&mut uri, collection);
        uri
    }

    fun get_token_uri(creator: address, collection: String, token_name: String): String {
        let addr_vec_out = to_bytes(&creator);
        let addr_string = from_bcs::to_string(addr_vec_out);
        let uri = string::utf8(b"nft://");
        string::append(&mut uri, addr_string);
        string::append(&mut uri, string::utf8(b"/"));
        string::append(&mut uri, collection);
        string::append(&mut uri, string::utf8(b"/"));
        string::append(&mut uri, token_name);
        uri
    }
}