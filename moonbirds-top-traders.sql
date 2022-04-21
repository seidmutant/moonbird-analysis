WITH nft_trades AS (
    SELECT *  
    FROM nft.trades
    WHERE
        original_amount > 0.0 
        AND "trade_type" = 'Single Item Trade'
        AND original_currency IN ('ETH', 'WETH')
        AND block_time >= '2022-04-16 14:00'
        --- mint started @ 2022-04-16 15:00
        --- mint completed @ 2022-04-16 19:00
        AND nft_contract_address = '\x23581767a106ae21c074b2276D25e5C3e136a68b'    
),

buyer_metrics AS (
    SELECT 
        buyer AS wallet_address, 
        COUNT(DISTINCT nft_token_ids_array) AS count_buys,
        SUM(original_amount) AS total_amount_buy,
        AVG(original_amount) AS avg_amount_buy,
        MIN(original_amount) AS min_amount_buy,
        MAX(original_amount) AS max_amount_buy
    FROM nft_trades
    GROUP BY 1
),

seller_metrics AS (
    SELECT 
        seller AS wallet_address, 
        COUNT(DISTINCT nft_token_ids_array) AS count_sells,
        SUM(original_amount) AS total_amount_sell,
        AVG(original_amount) AS avg_amount_sell,
        MIN(original_amount) AS min_amount_sell,
        MAX(original_amount) AS max_amount_sell     
    FROM nft_trades
    GROUP BY 1
),

flip_trades AS (
    SELECT 
        A.nft_token_ids_array,
        A.buyer AS wallet_address,
        B.original_amount - A.original_amount AS flip_profit,
        B.block_time - A.block_time AS date_diff,
        A.block_time AS block_time_buy,
        B.block_time AS block_time_sell        
    FROM nft_trades AS A
    JOIN nft_trades AS B
    ON 
        A.nft_token_ids_array = B.nft_token_ids_array
        AND A.buyer = B.seller
    WHERE B.seller IS NOT NULL
),

flip_metrics AS (
    SELECT 
        wallet_address, 
        COUNT(DISTINCT nft_token_ids_array) AS total_flip_tokens,
        SUM(flip_profit) AS total_flip_profit,
        MIN(flip_profit) AS min_flip_profit,
        MAX(flip_profit) AS max_flip_profit,
        AVG(flip_profit) AS avg_flip_profit,
        MIN(block_time_buy) AS min_block_time_buy,
        AVG(date_diff) AS avg_selling_time
    FROM flip_trades
    GROUP BY 1
)

SELECT 
    A.wallet_address, 
    A.count_buys,
    B.count_sells,
    --- buy metrics
    A.total_amount_buy,
    A.avg_amount_buy,
    A.min_amount_buy,
    A.max_amount_buy,
    --- sell metrics
    B.total_amount_sell,
    B.avg_amount_sell,
    B.min_amount_sell,
    B.max_amount_sell,
    --- flip metrics
    C.total_flip_tokens,
    C.total_flip_profit,
    C.min_flip_profit,
    C.max_flip_profit,
    C.avg_flip_profit,   
    C.min_block_time_buy,
    C.avg_selling_time      
FROM buyer_metrics AS A
JOIN seller_metrics AS B
ON A.wallet_address = B.wallet_address
LEFT JOIN  flip_metrics AS C
ON A.wallet_address = C.wallet_address
ORDER BY total_flip_profit DESC