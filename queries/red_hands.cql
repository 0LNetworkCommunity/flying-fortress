// Done as a last pass after all the other crawls are considered.
// These are two cases which have clear behavior of programatic
// creating and transferring to funnel to OTC.
// We use this to double check that the algorithm above caught any edge cases
// that are missing.
// This is expected to be a 90% + overlap with above algorithm.

WITH [
// CASE A
// CWs
'7B61439A88060096213AC4F5853B598E',
'5E68026887147DE0EA9CA90962C25A41',
'97DCBC6BFAA7EDF00F9002DAAED49C46',
'DA38C9B3AB9D81F6E160A712EB80D660',
// Validator Accounts
'6DA2B828F3018637379203940C639A95', // mother
'27E9577869ADFD677DBA9C940DEECE0A', // father
'988B8C3B7E55B6E5126884E02C8F166E', // public validator
// Funnels to OTC
'9A819C21AC342AAE6BB7B4F9AA65D1C2',
'0000000A370489B51D0FB02EDF4F3BED',
'000000CD4D3072EF9EE52BE59D7B0C99',
'60F521D85586C395D881CDD915FC5C0E',
'C68EA913FDF0FC1DE5B5E3B6B59D0E62',
'0E8F2BB0160EC00FB8721D99CFCBAA8C',
'D28F5A825F3AFD1147F6604642F312AD',
'B78662363A2644DB3A0A6063179CB551',
'70B88026EEE59CDA454B9B96165D0342',

// CASE C
// CW
"AD9F8E672AC60CE6473891CDC42EDBB8",
// Funnels
"095821475D18A4BF4F23D86D59D0E384",
"69D0EF8E8A20962E392046192E248835",
"F349DEE4236356ADA0945E0A421D773A"

] AS confessionBox

MATCH createPath=(cw:Wallet)-[:CREATED*..4]-(dest:Wallet)
WHERE cw.address in confessionBox
AND NOT dest.address in confessionBox
AND ALL(n in nodes(createPath)
  WHERE NOT n.address in $excludedCWAddresses
)

// RETURN createPath

MATCH txPath=(cw:Wallet)-[:TRANSFERRED|CW_PAYMENT*..2]-(dest)
WHERE cw.address in confessionBox
AND NOT dest.address in confessionBox
AND NONE(n in nodes(txPath)
  WHERE n.address in $excludedCWAddresses
)

UNWIND nodes(txPath) as NodeInTxPath
RETURN DISTINCT NodeInTxPath as wallet
