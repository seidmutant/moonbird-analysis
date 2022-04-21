WITH event_transfer_mint AS (
    SELECT 
        contract_address,
        evt_tx_hash,
        evt_block_time,
        "to" AS to_address, 
        "from" AS from_address,
        "tokenId" AS token_id
    FROM erc721."ERC721_evt_Transfer"
    WHERE 
        evt_block_time >= '2022-03-15 00:00'
        AND "from" = '\x0000000000000000000000000000000000000000'
),

event_transfer_mint_with_price AS (
    SELECT 
        DISTINCT
        A.evt_tx_hash,
        A.evt_block_time,
        A.contract_address,
        A.to_address,
        A.from_address,
        A.token_id,
        B.value/10^18 AS price_eth
    FROM event_transfer_mint AS A
    INNER JOIN ethereum.transactions AS B
    ON A.evt_tx_hash = B.hash
    WHERE B.block_time > '2022-03-15 00:00'
),

----
-- CONTRACT METRICS
----
contract_metrics_calculation AS (
    SELECT 
        contract_address,
        MIN(price_eth) AS min_price_eth,
        MAX(price_eth) AS max_price_eth,
        AVG(CASE WHEN price_eth > 0 THEN price_eth ELSE NULL END) AS avg_price_eth,
        MIN(CASE WHEN price_eth > 0 THEN evt_block_time ELSE NULL END) AS min_evt_tx_hash,
        COUNT(DISTINCT token_id) AS count_distinct_tokens
    FROM event_transfer_mint_with_price
    GROUP BY 1
),

contract_metrics AS (
    SELECT * 
    FROM contract_metrics_calculation
    WHERE 
        min_evt_tx_hash > '2022-03-15 00:00' 
        AND count_distinct_tokens > 9900
        AND count_distinct_tokens < 11000
        AND avg_price_eth > 0.00
),

-----
--- TRADING VOLUME
--- Calculate trading volume for 6 hours after launch
-----
nft_trading_volume AS (
    SELECT 
        B.contract_address, 
        SUM(original_amount) AS trading_volume
    FROM nft.trades AS A
    JOIN contract_metrics AS B
    ON A.nft_contract_address = B.contract_address
    WHERE  
        original_amount > 0.0 
        AND A.block_time >= min_evt_tx_hash AND A.block_time < (DATE_TRUNC('minute', min_evt_tx_hash) + interval '6 hours')
        AND original_currency IN ('ETH', 'WETH')
        AND A.block_time > '2022-03-15 00:00'
    GROUP BY 1
),

------
-- BLUE CHIP METRICS
--- Get all TO addresses who have purchased a blue chip NFT
-------
blue_chip_collection_buyers AS (
    SELECT DISTINCT "to" AS to_address
    FROM erc721."ERC721_evt_Transfer"
    WHERE 
        contract_address IN (
            --- Bored Apes https://etherscan.io/address/0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D
            '\xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D', 
            --- Mutant Apes https://etherscan.io/address/0x60e4d786628fea6478f785a6d7e704777c86a7c6
            '\x60E4d786628Fea6478F785A6d7e704777c86a7c6',
            --- Azuki https://etherscan.io/token/0xed5af388653567af2f388e6224dc7c4b3241c544
            '\xED5AF388653567Af2F388E6224dC7C4b3241C544',
            --- CryptoPunsk https://etherscan.io/token/0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb
            '\xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB'
        )  
),

contract_metrics_with_blue_chip AS (
    SELECT 
        A.contract_address,          
        COUNT(DISTINCT A.token_id) AS total_mints,
        COUNT(DISTINCT A.to_address) AS unique_addresses,
        COUNT(DISTINCT CASE WHEN C.to_address IS NOT NULL THEN A.token_id ELSE NULL END) AS total_blue_chip,
        COUNT(DISTINCT CASE WHEN C.to_address IS NOT NULL THEN C.to_address ELSE NULL END) AS unique_blue_chip
    FROM event_transfer_mint AS A
    JOIN contract_metrics AS B
    --- filter down to only contracts we care about
    ON A.contract_address = B.contract_address
    LEFT JOIN blue_chip_collection_buyers AS C
    ON A.to_address = C.to_address
    GROUP BY 1
)

----- 
-- FINAL
------
SELECT 
    A.contract_address,
    A.min_evt_tx_hash,
    A.min_price_eth,
    A.max_price_eth,
    A.avg_price_eth,           
    B.total_mints,
    B.unique_addresses,
    B.total_blue_chip,
    B.unique_blue_chip,
    C.trading_volume          
FROM contract_metrics AS A
LEFT JOIN contract_metrics_with_blue_chip AS B
ON A.contract_address = B.contract_address
LEFT JOIN nft_trading_volume AS C
ON A.contract_address = C.contract_address