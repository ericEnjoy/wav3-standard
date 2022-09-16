# NFT standard

The standard is an extension of the token contract in the Aptos framework to provide a richer ecosystem for Aptos NFT.
The extensions will be done in two parts, one is the collection, and the other is the token.
![Image](./image/image.png)
# Collections

The standard extension is based on [token.move](https://github.com/aptos-labs/aptos-core/blob/main/aptos-move/framework/aptos-token/sources/token.move) in aptos-token.
[token.move](https://github.com/aptos-labs/aptos-core/blob/main/aptos-move/framework/aptos-token/sources/token.move) defined the fields in the collection section as following.

|Metadata	|Type	|Description	|
|---	|---	|---	|
|description	|string 	|Used to describe the collection	|
|name	|string 	|Collection name	|
|uri	|string 	|Used to locate additional information of this collection	|
|supply	|u64	|The total amount of token_data issued by the current collection	|
|maximum	|u64 	|The maximum number of token_data this collection can issue	|
|mutability_config	|Collection MutabilityConfig |Defines the mutability of description, uri, and maximum|


## extend_property

The extension standard will be implemented using a contract, and the extension properties defined in the contract can be located by uri. uri is described as nft://{contract_address}/{creator::collection}

|Metadata	|Type	|Description	|
|---	|---	|---	|
|social_media	|map 	|Describe the link to each social media account of the collection, e.g. twitter: twitter_url	|
|symbol	|string 	|Abbreviated descriptions of collections, such as ENS for Ethereum Name Service	|
|image_url	|string 	|Collection cover image link	|
|animation_url	|string 	|Collection of additional multimedia data links such as gif	|
|website	|string 	|Collection corresponding official website address	|
|standard_version	|u64	|The version number will be updated when the collection data is updated.	|
|commercial_standard	|string	|Used to describe the business protocol standards that collection adheres to, such as cc0, cc by	|
|update_timestamp	|u64	|Record the timestamp of the last update of the collection, track the update time and compare the content before and after the update	|
|royalty_policy	|string 	|Describes  which royalty policy to follow，such as x2y2	|


# Token

## The Non-Fungible Standard

### extend_property

The extension standard will be implemented using a contract, and the extension properties defined in the contract will be located by uri. Uri is described as nft://{contract_address}/{creator::collection::name}

|Metadata	|Type	|Description	|
|---	|---	|---	|
|image_url	|string	|Token image url	|
|animation_url	|string	|Token Additional multimedia data links, such as gif	|
|image_checksum	|u64	|For verifying the authenticity of the image	|
|mutability_config	|bool 	|Describe whether the image can be changed	|

## Reference

* https://github.com/aptos-labs/aptos-core/blob/8b826d88b0f17255a753214ede48cbc44e484a97/ecosystem/web-wallet/src/core/types/TokenMetadata.ts
* https://github.com/aptos-labs/aptos-core/blob/main/aptos-move/framework/aptos-token/sources/token.move
* https://docs.metaplex.com/programs/token-metadata/token-standard#the-non-fungible-standard

