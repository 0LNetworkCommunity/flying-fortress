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

    # Add your sanity check logic here
    typer.echo("Balance export completed.")


# Explicitly register the commands without decorators
app.command("sanity")(sanity_command)
app.command("balance")(balance_command)



if __name__ == "__main__":
    app()
    cli_manager.disconnect()
