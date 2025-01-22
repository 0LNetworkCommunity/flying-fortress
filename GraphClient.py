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
                "balance": record["balance"],
                "unlocked": record["unlocked"],
                "daily_pct": record["daily_pct"],
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
                "total_out": record["total_out"], #don't scale, the query already does it
              }
              balances.append(balance_data)
            with open('root_sprayers.json', 'w') as json_file:
              json.dump(balances, json_file, indent=2)
            return result

  def get_spray_tree(self):
      with open('queries/spray_tree.cql', 'r') as file:
        cypher_query = file.read()
        with self.driver.session() as session:
            params = { "root_sprayer": "0xbd6323842b5dc76e178ae7eaeacce7f" }
            result = session.run(cypher_query, params)
            balances = []
            for record in result:
              balance_data = {
                "root" : params["root_sprayer"],
                "address": record["address"]
              }
              balances.append(balance_data)
            with open('spray_tree.json', 'w') as json_file:
              json.dump(balances, json_file, indent=2)
            return result

  def get_spray_tree_with_balances(self):
      with open('queries/spray_tree_with_balances.cql', 'r') as file:
        cypher_query = file.read()
        with self.driver.session() as session:
            # params = { "root_sprayer": root_sprayer_literal}
            result = session.run(cypher_query, params)
            balances = []
            total_sum = 0
            for record in result:
              print(record)
              balance_data = {
                "address": record["address"],
                "root_sprayer" : record["root_sprayer"],
                "root_sprayer_out": record["root_sprayer_out"],
                "balance": record["balance"],
                "daily_pct": record["daily_pct"]
              }
              total_sum = total_sum + record["balance"]
              balances.append(balance_data)
            print("total balance in tree {:,}".format(total_sum))
            with open('spray_tree_with_balances.json', 'w') as json_file:
              json.dump(balances, json_file, indent=2)
            return result
