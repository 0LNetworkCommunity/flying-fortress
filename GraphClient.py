# GraphClient.py
from QueryParams import params
from neo4j import GraphDatabase


class Neo4jClient:
  def __init__(self, uri, username, password):
    self.uri = uri
    self.username = username
    self.password = password
    self.driver = None

  def connect(self):
    self.driver = GraphDatabase.driver(self.uri, auth=(self.username, self.password))

  def close(self):
    if self.driver:
      self.driver.close()

  def execute_query(self, cypher_query, parameters=None):
    with self.driver.session() as session:
      result = session.run(cypher_query, parameters)
      result_data = [dict(record["wallet"]) for record in result if record["wallet"]]
      return result_data

  def get_striked_accounts(self):
      with open('queries/get_striked.cql', 'r') as file:
        cypher_query = file.read()
      return self.execute_query(cypher_query, params)

  def red_hands(self):
    with open('queries/red_hands.cql', 'r') as file:
      cypher_query = file.read()
    return self.execute_query(cypher_query, params)

  def identify_cabal(self, seed_wallet_address):
    with open('queries/id_cabal.cql', 'r') as file:
      cypher_query = file.read()
    params["seedWalletAddress"] = seed_wallet_address
    return self.execute_query(cypher_query, params)
