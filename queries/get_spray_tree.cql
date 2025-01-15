WITH 1_000_000 AS scaling,
1_000_000 AS tree_value_threshold,
1_000 AS tx_amount,
[
// OLswap
"0xf57d3968d0bfd5b3120fda88f34310c70bd72033f77422f4407fbbef7c24557a",
// osmosis
 "0x7153a13691e832ec5c5e2f0503fb7d228fbb7c87dd0c285c29d3f1d9f320cd5c",
// base
"0x8d57a33412c4625289e35f2843e1d36ea19fa6bde7816b1e3607c694926f01ae",
// david onboarding
"0x7355e047e103e2bb5f31137d068ad68d",
// nima onboarding
"0x85b68bdeb3bd8ca47f1cf90dfb332404290afda582c586cb645b3b045b54825b"

] AS ignore


MATCH p=(from:Account)-[t:Tx]->(to:Account)
 WHERE (
    t.V7_OlAccountTransfer_amount/scaling > tx_amount
    OR t.V7_CoinTransfer_amount/scaling > tx_amount
    OR t.V5_BalanceTransfer_unscaled_value/scaling > (tx_amount/35)
  )
  AND(
    NOT from.address IN ignore
    AND NOT to.address IN ignore
  )


WITH DISTINCT(from) AS from_filter, count(DISTINCT to) as destinations, (sum(t.V7_OlAccountTransfer_amount/scaling) + sum(t.V7_CoinTransfer_amount/scaling) + sum(t.V5_BalanceTransfer_unscaled_value/scaling * 35)) AS total, tree_value_threshold, ignore

WHERE destinations > 5
AND total > tree_value_threshold

MATCH p = shortest 1 (from_filter)-[:Tx]->()-[:Tx]->()
  WITH NOT from.address IN ignore
  AND NOT to.address IN ignore
RETURN p
