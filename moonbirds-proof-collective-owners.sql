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

moonbird_proof_table_flat AS (
    SELECT 
        A.to_address AS to_address_moonbird, 
        A.token_id AS token_id_moonbird, 
        B.to_address AS to_address_proof, 
        B.token_id AS token_id_proof
    FROM moonbird_holders_final AS A
    FULL OUTER JOIN proof_collective_holders_final AS B
    ON A.to_address = B.to_address
)

SELECT
    COUNT(DISTINCT to_address_proof) AS count_to_address_proof,
    COUNT(DISTINCT to_address_moonbird) AS count_to_address_moonbird,
    COUNT(DISTINCT(CASE WHEN to_address_proof IS NOT NULL AND to_address_moonbird IS NOT NULL THEN to_address_proof ELSE NULL END))
FROM moonbird_proof_table_flat