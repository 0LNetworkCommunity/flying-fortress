WITH [
  '0xf57d3968d0bfd5b3120fda88f34310c70bd72033f77422f4407fbbef7c24557a',
  '0x7153a13691e832ec5c5e2f0503fb7d228fbb7c87dd0c285c29d3f1d9f320cd5c',
  '0x8d57a33412c4625289e35f2843e1d36ea19fa6bde7816b1e3607c694926f01ae',
  '0x7355e047e103e2bb5f31137d068ad68d',
  '0x85b68bdeb3bd8ca47f1cf90dfb332404290afda582c586cb645b3b045b54825b'] as ignore
MATCH (accs:Account)
WHERE NOT accs.address IN ignore
AND accs.community IS NOT NULL

WITH DISTINCT accs.community AS cm_id, count(accs) as ct, ignore
ORDER BY ct DESC
WHERE ct > 4
SKIP 10
LIMIT 1

MATCH (core:Account)
WHERE core.community IN [cm_id]
AND NOT core.address IN ignore

MATCH (core)-[:State]->(s:Snapshot)

WITH sum(s.balance)/1_000_000 as group_total, collect(core.address) as list, cm_id


MATCH (a:Account)-[:State]->(s2:Snapshot)
WHERE a.address in list
AND s2.donor_voice = false
WITH s2.balance / 1_000_000 as balance, s2.address AS address, group_total, toFloat(group_total)/35_000/365  AS years_unlock, cm_id
RETURN address, balance, group_total, years_unlock, cm_id

ORDER BY balance DESC
