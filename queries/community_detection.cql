MATCH (a:Account)
REMOVE a.community;
WITH [
  '0xf57d3968d0bfd5b3120fda88f34310c70bd72033f77422f4407fbbef7c24557a',
  '0x7153a13691e832ec5c5e2f0503fb7d228fbb7c87dd0c285c29d3f1d9f320cd5c',
  '0x8d57a33412c4625289e35f2843e1d36ea19fa6bde7816b1e3607c694926f01ae',
  '0x7355e047e103e2bb5f31137d068ad68d',
  '0x85b68bdeb3bd8ca47f1cf90dfb332404290afda582c586cb645b3b045b54825b'] as ignore

MATCH (a:Account)-[r:Lifetime]-(b:Account)
WHERE a <> b
AND NOT a.address IN ignore
AND r.coins > 1_000_000
SET a.community = elementId(a);

// can't do loops in cypher
CALL apoc.periodic.iterate(
  "MATCH (a:Account)-[r:Lifetime]-(b:Account)
  WHERE a.community IS NOT NULL
  AND b.community IS NOT NULL
  AND b.community > a.community
  AND r.coins > 10_000
  RETURN a, b",
  "SET b.community = a.community",
  {batchSize: 10000, parallel: false}
);

CALL apoc.periodic.iterate(
  "MATCH (a:Account)-[r:Lifetime]-(b:Account)
  WHERE a.community IS NOT NULL
  AND b.community IS NOT NULL
  AND b.community > a.community
  AND r.coins > 10_000
  RETURN a, b",
  "SET b.community = a.community",
  {batchSize: 10000, parallel: false}
);

CALL apoc.periodic.iterate(
  "MATCH (a:Account)-[r:Lifetime]-(b:Account)
  WHERE a.community IS NOT NULL
  AND b.community IS NOT NULL
  AND b.community > a.community
  AND r.coins > 10_000
  RETURN a, b",
  "SET b.community = a.community",
  {batchSize: 10000, parallel: false}
);

CALL apoc.periodic.iterate(
  "MATCH (a:Account)-[r:Lifetime]-(b:Account)
  WHERE a.community IS NOT NULL
  AND b.community IS NOT NULL
  AND b.community > a.community
  AND r.coins > 10_000
  RETURN a, b",
  "SET b.community = a.community",
  {batchSize: 10000, parallel: false}
);

CALL apoc.periodic.iterate(
  "MATCH (a:Account)-[r:Lifetime]-(b:Account)
  WHERE a.community IS NOT NULL
  AND b.community IS NOT NULL
  AND b.community > a.community
  AND r.coins > 10_000
  RETURN a, b",
  "SET b.community = a.community",
  {batchSize: 10000, parallel: false}
);

CALL apoc.periodic.iterate(
  "MATCH (a:Account)-[r:Lifetime]-(b:Account)
  WHERE a.community IS NOT NULL
  AND b.community IS NOT NULL
  AND b.community > a.community
  AND r.coins > 10_000
  RETURN a, b",
  "SET b.community = a.community",
  {batchSize: 10000, parallel: false}
);

CALL apoc.periodic.iterate(
  "MATCH (a:Account)-[r:Lifetime]-(b:Account)
  WHERE a.community IS NOT NULL
  AND b.community IS NOT NULL
  AND b.community > a.community
  AND r.coins > 10_000
  RETURN a, b",
  "SET b.community = a.community",
  {batchSize: 10000, parallel: false}
);


MATCH (a:Account)
RETURN count(DISTINCT a.community)
