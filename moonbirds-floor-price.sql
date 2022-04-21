SELECT 
    DATE_TRUNC('hour', block_time) as block_time_hour,
    percentile_cont(.100) WITHIN group (ORDER BY original_amount) AS floor_price,
    percentile_cont(.500) WITHIN group (ORDER BY original_amount) AS avg_price
FROM nft.trades t
WHERE 
    nft_contract_address = '\x23581767a106ae21c074b2276D25e5C3e136a68b'
    AND original_amount > 0.0
    AND "trade_type" = 'Single Item Trade'
    AND "tx_from" != '0x0000000000000000000000000000000000000000'
    AND original_currency IN ('ETH', 'WETH')
GROUP BY 1
ORDER BY 1