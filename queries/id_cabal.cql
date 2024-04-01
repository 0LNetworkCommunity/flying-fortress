// Initialize key variables from parameters
WITH
$seedWalletAddress AS seedWalletAddress,
$swapWalletAddress AS swapWalletAddress,
$excludedCWAddresses AS excludedCWAddresses

// Identify the specific seed and swap wallets based on their addresses
MATCH
(seedWallet:Wallet { address: seedWalletAddress }),
(swapWallet:Wallet { address: swapWalletAddress })

// Find all first-degree INCOMING relationships to the seed wallet
OPTIONAL MATCH p_in=(a_in:Wallet)-[r_in:CREATED|AUTOPAY|TRANSFERRED|CW_PAYMENT]->(seedWallet)
WHERE NONE(node IN nodes(p_in) WHERE node.address IN excludedCWAddresses)
// Collect paths and wallets to pass forward
WITH
seedWallet,
swapWallet,
seedWalletAddress,
excludedCWAddresses,
COLLECT(p_in) AS pathsIn,
COLLECT(a_in) AS firstDegreeIn

// For each wallet found in the first step, find any wallets they have paid to via AUTOPAY
UNWIND firstDegreeIn AS fdIn
OPTIONAL MATCH p_autopay=(fdIn)-[r_autopay:AUTOPAY]->(other:Wallet)
WHERE NOT other.address IN excludedCWAddresses AND other.address <> seedWalletAddress
// Collect paths and wallets to pass forward
WITH
seedWallet,
swapWallet,
excludedCWAddresses,
firstDegreeIn,
pathsIn,
COLLECT(p_autopay) AS autopayPaths,
COLLECT( DISTINCT other) AS otherAutopayRecipients

// Find wallets directly created by the seed wallet
OPTIONAL MATCH p_created=(seedWallet)-[r_created:CREATED]->(a_created_out:Wallet)
WHERE NOT a_created_out.address IN excludedCWAddresses
// Collect paths and wallets to pass forward
WITH
seedWallet,
swapWallet,
excludedCWAddresses,
firstDegreeIn,
otherAutopayRecipients,
autopayPaths,
pathsIn,
COLLECT(p_created) AS pathsCreated,
COLLECT( DISTINCT a_created_out) AS firstDegreeCreatedOut

// Look for transfer events initiated by the seed wallet, (v6 transfer bug)
OPTIONAL MATCH p_out_transferred=(seedWallet)-[r_out_transferred:TRANSFERRED]->(a_out_transferred:Wallet)
WHERE NONE(node IN nodes(p_out_transferred) WHERE node.address IN excludedCWAddresses)
AND r_out_transferred.v = "v6" AND r_out_transferred.amount > $maxTransferredAmount
// Collect paths and wallets to pass forward
WITH
seedWallet,
swapWallet,
excludedCWAddresses,
firstDegreeIn,
otherAutopayRecipients,
autopayPaths,
pathsIn,
pathsCreated,
COLLECT(p_out_transferred) AS pathsOutTransferred,
COLLECT(a_out_transferred) AS firstDegreeOutTransferred

// Similarly, find CW_PAYMENT events from the seed wallet
OPTIONAL MATCH p_out_cw=(seedWallet)-[r_out_cw:CW_PAYMENT]->(a_out_cw:Wallet)
WHERE NONE(node IN nodes(p_out_cw) WHERE node.address IN excludedCWAddresses)
// Collect paths and wallets to pass forward
WITH
seedWallet,
swapWallet,
excludedCWAddresses,
firstDegreeIn,
otherAutopayRecipients,
autopayPaths,
pathsIn,
pathsCreated,
pathsOutTransferred,
firstDegreeOutTransferred,
COLLECT(p_out_cw) AS pathsOutCW,
COLLECT(a_out_cw) AS firstDegreeOutCW

// Combine results of different relationship types for the final list of first-degree relationships out from the seed wallet
WITH
seedWallet,
swapWallet,
excludedCWAddresses,
firstDegreeIn,
otherAutopayRecipients,
autopayPaths,
pathsIn,
pathsCreated,
pathsOutTransferred,
firstDegreeOutTransferred,
pathsOutCW,
firstDegreeOutCW,
firstDegreeOutTransferred + firstDegreeOutCW AS firstDegreeOut

// For each of the first-degree out nodes, find wallets that received a TRANSFERRED relationship
OPTIONAL MATCH p_received=(a_out)-[r_received:TRANSFERRED]->(recipient:Wallet)
WHERE a_out IN firstDegreeOut
 AND NONE(node IN nodes(p_received) WHERE node.address IN excludedCWAddresses)
 AND r_received.amount > $minRecievedAmount
// Collect paths and wallets to pass forward
WITH
seedWallet,
swapWallet,
excludedCWAddresses,
firstDegreeIn,
otherAutopayRecipients,
autopayPaths,
pathsIn,
pathsCreated,
firstDegreeOut,
COLLECT(p_received) AS pathsReceived,
COLLECT( DISTINCT recipient) AS recipientsOfTransferred

// Identify the creators of the recipient wallets
OPTIONAL MATCH p_recipient_creator=(recipient_creator:Wallet)-[:CREATED]->(recipient)
WHERE recipient IN recipientsOfTransferred
AND NONE(node IN nodes(p_recipient_creator) WHERE node.address IN excludedCWAddresses)
// Collect paths and wallets to pass forward
WITH
seedWallet,
swapWallet,
excludedCWAddresses,
firstDegreeIn,
otherAutopayRecipients,
autopayPaths,
pathsIn,
pathsCreated,
pathsReceived,
firstDegreeOut,
recipientsOfTransferred,
COLLECT(p_recipient_creator) AS pathsCreator,
COLLECT( DISTINCT recipient_creator) AS creatorsOfRecipients

// Find next hop TRANSFERRED relationships from the recipients, 2nd degree transfers
OPTIONAL MATCH p_recipient_received=(recipient)-[r_recipient_received:TRANSFERRED]->(finalRecipient:Wallet)
WHERE recipient IN recipientsOfTransferred
AND NONE(node IN nodes(p_recipient_received) WHERE node.address IN excludedCWAddresses)
AND r_recipient_received.amount > $minRecievedAmount
// Prepare final collections for output
WITH
seedWallet,
swapWallet,
excludedCWAddresses,
firstDegreeIn,
otherAutopayRecipients,
autopayPaths,
pathsIn,
pathsCreated,
pathsReceived,
firstDegreeOut,
recipientsOfTransferred,
creatorsOfRecipients,
pathsCreator,
COLLECT(p_recipient_received) AS pathsRecipientReceived,
COLLECT( DISTINCT finalRecipient) AS finalRecipientsOfTransferred

// Identify the creator of the seed wallet and consider relationships to second-degree connections
OPTIONAL MATCH (creatorOfSeed:Wallet)-[:CREATED]->(seedWallet)
// Traverse from the creator to find CREATED followed by TRANSFERRED relationships
OPTIONAL MATCH p_creator_to_transfer=(creatorOfSeed)-[:CREATED]->(created:Wallet)-[:TRANSFERRED]->(transferred:Wallet)
WHERE NONE(node IN nodes(p_creator_to_transfer) WHERE node.address IN excludedCWAddresses)
AND created.validator = False
// Collect these paths for analysis
WITH
seedWallet,
swapWallet,
excludedCWAddresses,
firstDegreeIn,
otherAutopayRecipients,
autopayPaths,
pathsIn,
pathsCreated,
pathsReceived,
firstDegreeOut,
recipientsOfTransferred,
creatorsOfRecipients,
pathsCreator,
pathsRecipientReceived,
finalRecipientsOfTransferred,
COLLECT(p_creator_to_transfer) AS pathsFromCreatorThroughTransferred

// Finally, find the shortest path from each of the final recipients to the swap wallet, within a limit of 3 TRANSFERRED hops, excluding specified addresses
OPTIONAL MATCH shortestPathToSwap = shortestPath((recipient:Wallet)-[:TRANSFERRED*1..3]->(swapWallet))
WHERE recipient IN finalRecipientsOfTransferred
 AND swapWallet <> recipient
 AND ALL(node IN nodes(shortestPathToSwap)[1..-1] WHERE NOT node.address IN excludedCWAddresses)

// Aggregate all paths and relevant nodes for final output
WITH
seedWallet,
firstDegreeIn + firstDegreeOut AS allFirstDegreeRelations,
recipientsOfTransferred + finalRecipientsOfTransferred AS allRecipients,
creatorsOfRecipients,
otherAutopayRecipients,
COALESCE(pathsIn, []) + COALESCE(pathsCreated, []) + COALESCE(autopayPaths, []) + COALESCE(pathsReceived, []) + COALESCE(pathsCreator, []) + COALESCE(pathsRecipientReceived, []) + COALESCE(pathsFromCreatorThroughTransferred, []) + COALESCE(shortestPathToSwap, []) AS allPaths

// ### Collect nodes in python ##

// Collect and combine all direct relationship nodes
WITH
seedWallet,
allFirstDegreeRelations + allRecipients + creatorsOfRecipients + otherAutopayRecipients AS directNodes,
allPaths

// Unwind and collect nodes from paths
UNWIND allPaths AS path
UNWIND nodes(path) AS nodeFromPath
WITH
seedWallet,
directNodes,
COLLECT( DISTINCT nodeFromPath) AS nodesFromPaths

// Combine direct relationship nodes and nodes from paths
WITH
seedWallet,
directNodes + nodesFromPaths AS allNodesCombined

// Ensure seedWallet is included in the final list
WITH seedWallet + allNodesCombined AS allNodes

// Flatten the list for final processing
UNWIND allNodes AS finalNode
WITH DISTINCT finalNode AS uniqueNode
WHERE uniqueNode IS NOT null AND uniqueNode.address IS NOT null

RETURN uniqueNode AS wallet

// ### Collect nodes/paths/relations for visualization ##

// ### This return is used if want to visualize the output ###
// RETURN seedWallet AS SeedWallet,
// allFirstDegreeRelations AS FirstDegreeRelations,
// allRecipients AS AllRecipients,
// creatorsOfRecipients AS CreatorsOfRecipients,
// otherAutopayRecipients AS OtherAutopayRecipients,
// allPaths AS AllPaths
