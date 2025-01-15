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

  def get_sanity(self):
      with open('queries/sanity.cql', 'r') as file:
        cypher_query = file.read()
        with self.driver.session() as session:
          result = session.run(cypher_query)
          for record in result:
            print(record["addr"])
          return result

  def get_balances(self):
      with open('queries/balances.cql', 'r') as file:
        cypher_query = file.read()
        with self.driver.session() as session:
          result = session.run(cypher_query)
          for record in result:
            print(record["address"])
            print(record["balance"])
          return result
