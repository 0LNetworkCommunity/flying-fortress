WITH $root_sprayer as from_account,
1_000_000 AS scaling,
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

MATCH p=SHORTEST 1 (a:Account {address: from_account})-[r:Tx *..4]->(to:Account)
  WHERE none(
    n in nodes(p)
    where n.address in ignore
  )

WITH DISTINCT(to) as destinations, scaling

MATCH (destinations)-[:State]->(s:Snapshot {version: 94602328})

WHERE s.balance > scaling

RETURN destinations.address as address, s.balance/scaling as balance, s.slow_locked/scaling as locked, s.donor_voice as community_wallet
ORDER BY balance DESC
