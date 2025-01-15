# GraphClient.py
from QueryParams import params
from neo4j import GraphDatabase
import json


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
            balances = []
            for record in result:
              balance_data = {
                "address": record["address"],
                "balance": record["balance"] / 1_000_000,
                "locked": record["locked"] / 1_000_000,
                "cw": record["community_wallet"],
              }
              balances.append(balance_data)
            with open('balances.json', 'w') as json_file:
              json.dump(balances, json_file, indent=2)
            return result

  def get_root_sprayers(self):
      with open('queries/root_sprayers.cql', 'r') as file:
        cypher_query = file.read()
        with self.driver.session() as session:
            result = session.run(cypher_query)
            balances = []
            for record in result:
              balance_data = {
                "address": record["address"],
                "destinations": record["destinations"],
                "coins": record["total"], #don't scale, the query already does it
              }
              balances.append(balance_data)
            with open('root_sprayers.json', 'w') as json_file:
              json.dump(balances, json_file, indent=2)
            return result
