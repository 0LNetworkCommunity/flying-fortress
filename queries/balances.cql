WITH 1_000_000 AS scaling
MATCH
  (acc:Account)-[:State]->(snap:Snapshot {version: 94602328})
WHERE
  snap.balance > 1_000_000 * scaling
  AND snap.donor_voice = false

WITH acc.address as address, snap.balance/scaling AS balance, snap.slow_locked/scaling AS unlocked, toFloat(snap.slow_locked)/ toFloat(snap.balance) AS percent, ((toFloat(snap.balance)/ scaling)/ 35_000) as days_unlock, snap.donor_voice as community_wallet
RETURN address, balance, unlocked, percent, 1/days_unlock as daily_pct, community_wallet
ORDER BY balance DESC
