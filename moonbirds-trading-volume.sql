WITH trading_volume AS (
    SELECT 
        DATE_TRUNC('hour', A.block_time) AS block_time_hour,
        SUM(original_amount) AS trading_volume
    FROM nft.trades AS A
    WHERE  
        original_amount > 0.0 
        AND "trade_type" = 'Single Item Trade'
        AND original_currency IN ('ETH', 'WETH')
        AND block_time >= '2022-04-16 14:00'
        AND nft_contract_address = '\x23581767a106ae21c074b2276D25e5C3e136a68b'
    GROUP BY 1
)

SELECT * FROM trading_volume