import os
import typer
from GraphClient import Neo4jClient
from dotenv import load_dotenv

app = typer.Typer(help="A CLI tool for interacting with Neo4j and performing various tasks.")


class Neo4jCLI:
    def __init__(self):
        self.neo4j_client = None

    def init_neo4j_connection(self):
        """Initialize the connection to the Neo4j database."""
        load_dotenv()

        uri = os.getenv("NEO4J_URI")
        username = os.getenv("NEO4J_USERNAME")
        password = os.getenv("NEO4J_PASSWORD")

        if not uri or not username or not password:
            typer.echo("Error: Missing required environment variables: NEO4J_URI, NEO4J_USERNAME, NEO4J_PASSWORD.")
            raise typer.Exit(code=1)

        self.neo4j_client = Neo4jClient(uri, username, password)
        typer.echo(f"Connecting to Graph DB at {uri}...")
        self.neo4j_client.connect()
        typer.echo("...Connected!")

    def disconnect(self):
        """Close the Neo4j connection."""
        if self.neo4j_client:
            self.neo4j_client.close()
            typer.echo("Connection closed.")
            self.neo4j_client = None


# Instantiate the CLI manager
cli_manager = Neo4jCLI()
cli_manager.init_neo4j_connection()


def sanity_command():
    """Test connection to Neo4j."""
    typer.echo("Collecting all offending CWs")
    sanity = cli_manager.neo4j_client.get_sanity()
    typer.echo(f"Found {sanity} offending CWs")

def balance_command():
    typer.echo("Exporting balance...")
    balances = cli_manager.neo4j_client.get_balances()
    typer.echo("Balance export completed.")

def root_sprayers_command():
    typer.echo("Finding root sprayers...")
    balances = cli_manager.neo4j_client.get_root_sprayers()
    typer.echo("Root sprayers export completed.")

def spray_tree_command():
    typer.echo("Finding spray tree for addr...")
    balances = cli_manager.neo4j_client.get_spray_tree()
    typer.echo("Spray tree export completed.")

def spray_tree_balances_command():
    typer.echo("Finding spray tree for addr...")
    balances = cli_manager.neo4j_client.get_spray_tree_with_balances()
    typer.echo("Spray tree balances export completed.")

# Explicitly register the commands without decorators
app.command("sanity")(sanity_command)
app.command("balance")(balance_command)
app.command("root-sprayers")(root_sprayers_command)
app.command("spray-tree")(spray_tree_command)
app.command("spray-tree-balances")(spray_tree_balances_command)



if __name__ == "__main__":
    app()
    cli_manager.disconnect()
