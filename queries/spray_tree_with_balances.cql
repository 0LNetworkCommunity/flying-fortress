WITH 1_000_000 AS scaling,
1_000_000 AS tree_value_threshold,
1_000 AS tx_threshold,
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


MATCH p=(f:Account)-[t:Tx]->(to:Account)
 WHERE (
    t.V7_OlAccountTransfer_amount/scaling > tx_threshold
    OR t.V7_CoinTransfer_amount/scaling > tx_threshold
    OR t.V5_BalanceTransfer_unscaled_value/scaling > (tx_threshold/35)
  )
  AND(
    NOT f.address IN ignore
    AND NOT to.address IN ignore
  )


WITH DISTINCT(f) AS from_filter, collect(to) as destinations, count(DISTINCT to) as count_to, (sum(t.V7_OlAccountTransfer_amount/scaling) + sum(t.V7_CoinTransfer_amount/scaling) + sum(t.V5_BalanceTransfer_unscaled_value/scaling * 35)) AS total_out, tree_value_threshold, ignore, scaling

WHERE count_to > 5
AND total_out > tree_value_threshold

// RETURN from_filter.address, total_out, toFloat(total_out)/35000 as days_unlock
// ORDER BY days_unlock DESC

WITH DISTINCT(destinations) as temp, scaling, from_filter, total_out
UNWIND temp AS uniqueDestinations
MATCH (uniqueDestinations)-[:State]->(s:Snapshot {version: 94602328, donor_voice: false})
WHERE s.balance/scaling > 10_000

RETURN distinct(uniqueDestinations.address) as address, from_filter.address as root_sprayer, total_out as root_sprayer_out, s.balance/scaling as balance, 1/toFloat(total_out/35000) as daily_pct
ORDER BY root_sprayer_out DESC
