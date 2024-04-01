import os

from GraphClient import Neo4jClient
from utils import *
from tqdm import tqdm

# Flag to run sanity checks against a list of known accounts. See sanity_check.json
PERFORM_SANITY_CHECKS = True
SKIP_AND_IGNORE_CASE_A = False
EXCLUDE_VALIDATORS_FROM_FINAL_LIST = False
CUT_LIST_AT_HOOK_THRESHOLD = True
HOOK_THRESHOLD = 200_000

def main():
  ########## DB Access ##########
  uri = os.environ["NEO4J_URI"]
  username = os.environ["NEO4J_USERNAME"]
  password = os.environ["NEO4J_PASSWORD"]
  neo4j_client = Neo4jClient(uri, username, password)

  print("Opening connection to Graph DB")
  neo4j_client.connect()

  ########## Collecting nodes from the graph DB ##########

  print("Collecting all offending CWs")
  offending_cws = neo4j_client.get_striked_accounts()
  print("Found {} offending CWs".format(len(offending_cws)))

  if SKIP_AND_IGNORE_CASE_A:
    # filter out the slowest query
    offending_cws[:] = [cw for cw in offending_cws if cw['address'] != '7B61439A88060096213AC4F5853B598E']

  print("For each offending CW, finding their Cabal. ~18 minutes run here")
  all_cabals = []
  for cw in tqdm(offending_cws, desc="Identifying Cabals of offending CWs"):
    tqdm.write(f"Processing: {cw['address']}")
    cabal = neo4j_client.identify_cabal(cw['address'])
    print("Cabal size: ", len(cabal))
    all_cabals.extend(cabal)

  if not SKIP_AND_IGNORE_CASE_A:
    print("Running red hands for edge cases. ~3 minutes run here")
    red_handed_cabal = neo4j_client.red_hands()
    all_cabals.extend(red_handed_cabal)

  # Graph DB queries completed. Close connection
  neo4j_client.close()

  # Prepare list
  all_cabals = deduplicate_by_address(all_cabals)

  if EXCLUDE_VALIDATORS_FROM_FINAL_LIST:
    print("Removing validators from the cabal")
    all_cabals = [x for x in all_cabals if 'validator' not in x]

  print("Removing excluded accounts from the cabal")
  all_cabals = remove_excluded_from_cabal(all_cabals)



  if PERFORM_SANITY_CHECKS:
    print("Performing sanity checks")
    false_positive = perform_sanity_check(all_cabals)
    if false_positive:
        print("Caught unexpected addresses:")
        for address in false_positive:
            print(f"Account Address: {address.upper()}")
    else:
        print("No false positive entries found.")

  if CUT_LIST_AT_HOOK_THRESHOLD:
    final_cabal = [account for account in all_cabals if account.get('balance', 0.0) + account.get('locked', 0.0) > HOOK_THRESHOLD]
  else:
    final_cabal = all_cabals

  ########## Saving results locally ##########

  # Sort by address to make it easier to compare with other lists and align checksum
  final_cabal = sorted(final_cabal, key=lambda x: x['address'])

  print("Saving the final list of discontinued accounts to csv and json")

  save_to_csv(final_cabal, "fork_list.csv")
  save_to_json(final_cabal, "fork_list.json")
  # Next is the file that will be used during the network fork upgrade
  save_to_upgrade_json(final_cabal, "fork_list_upgrade.json")

  # Final stdout report
  coins_to_burn_count = calculate_accumulated_balance(final_cabal)
  print("Fork list generation complete. {:,} accounts have been flagged. Total Account balances to be dropped: {:,}"
        .format(len(final_cabal), coins_to_burn_count))

  print("""\n
  ******************************************\n
  Upgrade Fork list checksum: {}\n
  ******************************************\n""".format(calculate_checksum('fork_list_upgrade.json')))


if __name__ == "__main__":
  main()
