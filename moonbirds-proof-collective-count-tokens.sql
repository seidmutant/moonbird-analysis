WITH moonbird_holders AS (
  SELECT 
    "tokenId" AS token_id,
    "to" AS to_address,
    ROW_NUMBER() OVER (PARTITION BY contract_address, "tokenId" ORDER BY evt_block_time DESC) AS transction_rank
  FROM erc721."ERC721_evt_Transfer"
  WHERE 
    contract_address = '\x23581767a106ae21c074b2276D25e5C3e136a68b'
    AND evt_block_time > '2022-04-14 01:00'
),

moonbird_holders_final AS (
    SELECT * FROM moonbird_holders
    WHERE transction_rank = 1
),

proof_collective_holders AS (
  SELECT 
    "tokenId" AS token_id,
    "to" AS to_address,
    ROW_NUMBER() OVER (PARTITION BY contract_address, "tokenId" ORDER BY evt_block_time DESC) AS transction_rank
  FROM erc721."ERC721_evt_Transfer"
  WHERE 
    contract_address = '\x08D7C0242953446436F34b4C78Fe9da38c73668d'    
    AND evt_block_time > '2021-12-10 01:00'
),

proof_collective_holders_final AS (
    SELECT * FROM proof_collective_holders
    WHERE transction_rank = 1
),

moonbird_proof_table AS (
    SELECT 
        A.to_address, 
        COUNT(DISTINCT A.token_id) AS count_tokens
    FROM moonbird_holders_final AS A
    JOIN proof_collective_holders_final AS B
    ON A.to_address = B.to_address
    GROUP BY 1
)

SELECT count_tokens, COUNT(*) AS count_unique_addresses
FROM moonbird_proof_table
GROUP BY 1
ORDER BY 1