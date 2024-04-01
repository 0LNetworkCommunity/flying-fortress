import csv
import hashlib
import json
from QueryParams import params
from tqdm import tqdm

def print_to_stdout(result_data):
    print(json.dumps(result_data, indent=4))

def save_to_csv(data, filename):
    relevant_attributes = [
        'address', 'balance', 'locked', 'total_in', 'total_out', 'community', 'validator', 'minerstate_commit'
    ]

    with open(filename, 'w', newline='') as csvfile:
        # Write the header row with the specified attributes
        writer = csv.DictWriter(csvfile, fieldnames=relevant_attributes)
        writer.writeheader()

        # Write data rows with only the specified relevant_attributes
        for item in data:
            row = {key: item[key] for key in relevant_attributes if key in item}
            writer.writerow(row)

def save_to_json(data, filename):
    with open(filename, 'w') as jsonfile:
        json.dump(data, jsonfile, indent=4)

def save_to_upgrade_json(data, filename):
    upgraded_data = [{"account": '0x'+item["address"]} for item in data]

    with open(filename, 'w') as jsonfile:
        json.dump(upgraded_data, jsonfile, indent=4)


def save_to_postgres(result_data):
    pass  # TODO: Implement me


def deduplicate_by_address(objects):
    seen_addresses = set()
    deduplicated_objects = []
    for obj in objects:
        address = obj['address']
        if address not in seen_addresses:
            seen_addresses.add(address)
            deduplicated_objects.append(obj)
    return deduplicated_objects

def load_excluded_addresses(json_file='excluded.json'):
    with open(json_file, 'r') as file:
        data = json.load(file)
        # Convert addresses to lowercase for case-insensitive matching
        return [entry['account'].lower() for entry in data]

def remove_excluded_from_cabal(cabal):
    excluded_addresses = [account.lower() for account in params['excludedCWAddresses'] + params['graceExcludes']]
    removed_count = 0
    removed_balance = 0.0

    filtered_cabal = []

    for entry in cabal:
        cabal_address_lower = entry['address'].lower()
        if cabal_address_lower in excluded_addresses:
            balance = entry.get('balance', 0.0)
            locked = entry.get('locked', 0.0)
            removed_count += 1
            removed_balance += balance + locked
        else:
            filtered_cabal.append(entry)
    if removed_count > 0:
        print(f"Removed {removed_count} accounts listed in excluded.json, totaling balance: {removed_balance:,}")
    else:
        print("No accounts were removed based on excluded.json")

    return filtered_cabal

def load_innocent_addresses(json_file='innocents.json'):
    with open(json_file, 'r') as file:
        data = json.load(file)
        return [entry['account'] for entry in data]

def remove_innocents_from_cabal(neo4j_client, cabal):
    innocent_addresses = load_innocent_addresses()
    all_addresses_to_remove = set()  # Use a set to avoid duplicates and for efficient lookup
    removed_count = 0
    removed_balance = 0.0

    # First, collect all addresses to remove, including related addresses and the innocent addresses themselves
    for innocent_address in tqdm(innocent_addresses):
        related_wallets = neo4j_client.identify_innocents_subtrees(innocent_address)
        related_addresses = {wallet['address'].lower() for wallet in related_wallets}  # Collect related addresses
        all_addresses_to_remove.update(related_addresses)
        all_addresses_to_remove.add(innocent_address.lower())  # Add the innocent address itself

    # Now, filter the cabal list in one pass
    filtered_cabal = []
    dedup_cabal = deduplicate_by_address(cabal)
    for entry in dedup_cabal:
        cabal_address_lower = entry['address'].lower()
        if cabal_address_lower in all_addresses_to_remove:
            removed_count += 1
            removed_balance += entry.get('balance', 0.0) + entry.get('locked', 0.0)
        else:
            filtered_cabal.append(entry)

    print(f"Removed {removed_count} accounts related to innocents, totaling balance: {removed_balance}")

    return filtered_cabal

def read_addresses_from_json(json_file):
    addresses = {}
    with open(json_file) as jsonfile:
        data = json.load(jsonfile)
        for entry in data:
            address = entry['accountAddress'].lower()
            friendly_name = entry['friendlyName']
            addresses[address] = friendly_name
    return addresses

def perform_sanity_check(cabal):
    excluded_addresses = [account.lower() for account in params['excludedCWAddresses'] + params['graceExcludes']]
    flagged_entries = {}
    caught_addresses = [d['address'] for d in cabal]
    for entry in cabal:
        cabal_address = entry['address'].lower()
        if cabal_address in excluded_addresses:
            flagged_entries[cabal_address] = excluded_addresses[cabal_address]

    for entry in params['sanityIncludes']:
        if entry not in caught_addresses:
            print(f"ERROR: missing expected account! {entry}")

    return flagged_entries


def calculate_accumulated_balance(cabal):
    total = sum(item.get('balance', 0) + item.get('locked', 0) for item in cabal)
    return total

def calculate_checksum(file_path):
    """Calculate and print the SHA-256 checksum of a file."""
    sha256_hash = hashlib.sha256()
    try:
        with open(file_path, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        checksum = sha256_hash.hexdigest()
        return checksum
    except FileNotFoundError:
        print(f"File not found: {file_path}")
        return None
