// HARVESTING segment
WITH $excludedCWAddresses AS excludedCWAddresses
MATCH (cw:Wallet)<-[e:AUTOPAY]-(payer:Wallet)
WHERE cw.community = true AND NOT cw.address IN excludedCWAddresses
WITH cw, COLLECT( DISTINCT payer) AS payers
WHERE size(payers) >= 2 AND size(payers) < 10
RETURN DISTINCT cw AS wallet

UNION

// SPRAYING segment
WITH $excludedCWAddresses AS excludedCWAddresses
MATCH (cw:Wallet)-[p:CW_PAYMENT]->()
WHERE cw.community = true AND NOT cw.address IN excludedCWAddresses
WITH cw, COUNT(p) AS cwPaymentCount, SUM(p.amount) AS totalCwPaymentAmount
WHERE cwPaymentCount > 2 AND totalCwPaymentAmount > 50000
RETURN DISTINCT cw AS wallet

UNION

// TRANSFER_BUG segment
WITH $excludedCWAddresses AS excludedCWAddresses
MATCH (cw:Wallet)-[t:TRANSFERRED { v: "v6" }]->()
WHERE cw.community = true AND NOT cw.address IN excludedCWAddresses
WITH cw, SUM(t.amount) AS totalTransferred
WHERE totalTransferred > 1000000
RETURN DISTINCT cw AS wallet
