WITH nft_trading_volume_moonbird AS (
    SELECT 
        A.nft_contract_address AS contract_address, 
        'MOONBIRDS' AS contract_name,
        DATE_TRUNC('hour', A.block_time) AS block_time_hour,
        SUM(original_amount) AS trading_volume
    FROM nft.trades AS A
    WHERE  
        original_amount > 0.0 
        AND original_currency IN ('ETH', 'WETH')
        AND block_time >= '2022-04-16 14:00'
        --- mint started @ 2022-04-16 15:00
        --- mint completed @ 2022-04-16 19:00
        AND nft_contract_address = '\x23581767a106ae21c074b2276D25e5C3e136a68b'
    GROUP BY 1, 2, 3
),

nft_trading_volume_azuki AS (
    SELECT 
        A.nft_contract_address AS contract_address, 
        'AZUKI' AS contract_name,
        DATE_TRUNC('hour', A.block_time) AS block_time_hour,
        SUM(original_amount) AS trading_volume
    FROM nft.trades AS A
    WHERE  
        original_amount > 0.0 
        AND original_currency IN ('ETH', 'WETH')
        -- mint started at 2022-01-12 18:00
        -- mint completed at 2022-01-20 17:00
        AND block_time >= '2022-01-20 17:00' AND block_time <= '2022-01-22 17:00'
        AND nft_contract_address = '\xED5AF388653567Af2F388E6224dC7C4b3241C544'
    GROUP BY 1, 2, 3
)

SELECT *  FROM nft_trading_volume_moonbird AS A
UNION ALL
SELECT * FROM nft_trading_volume_azuki AS B

