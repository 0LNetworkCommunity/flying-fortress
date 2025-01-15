import os
import typer
from GraphClient import Neo4jClient
from dotenv import load_dotenv

app = typer.Typer(help="A CLI tool for interacting with Neo4j and performing various tasks.")


def connect_to_neo4j():
    """Connect to Neo4j and perform a sample query."""
    load_dotenv()

    uri = os.getenv("NEO4J_URI")
    username = os.getenv("NEO4J_USERNAME")
    password = os.getenv("NEO4J_PASSWORD")

    if not uri or not username or not password:
        typer.echo("Error: Missing required environment variables: NEO4J_URI, NEO4J_USERNAME, NEO4J_PASSWORD.")
        raise typer.Exit(code=1)

    neo4j_client = Neo4jClient(uri, username, password)

    typer.echo(f"Connecting to Graph DB at {uri}...")
    neo4j_client.connect()
    typer.echo("...Connected!")

    # Perform some Neo4j operations
    typer.echo("Collecting all offending CWs")
    sanity = neo4j_client.get_sanity()
    typer.echo(f"Found {sanity} offending CWs")

    # Close the connection
    neo4j_client.close()
    typer.echo("Connection closed.")


def perform_sanity_checks():
    """Perform sanity checks."""
    typer.echo("Performing sanity checks...")
    # Add the logic for sanity checks here
    typer.echo("Sanity checks completed.")


def another_task():
    """Perform another task."""
    typer.echo("Performing another task...")
    # Add logic for the task here
    typer.echo("Another task completed.")


# Adding commands to the CLI
app.command("connect")(connect_to_neo4j)
app.command("sanity-checks")(perform_sanity_checks)
app.command("another-task")(another_task)


if __name__ == "__main__":
    app()
