import datetime

import click
from click import pass_obj, pass_context

from ..app import create_app
from ..config import Config
from .event_server import run_event_server
from .app_server import run_app_server
from .cleanup_users import clean_users_loop, clean_users


@click.group()
@click.option("--config", "-c", type=click.File(), help="Filename of TOML config")
@pass_context
def cli(ctx, config):
  ctx.obj = {"CONFIG": Config.import_toml(config)}

@cli.command("event-server", help="Run the PUB/SUB server")
@pass_obj
def event_server(obj):
  run_event_server(obj["CONFIG"])

@cli.command("app-server", help="Run the WSGI server")
@pass_obj
def app_server(obj):
  run_app_server(obj["CONFIG"])

@cli.command("cleanup-users", help="Send users offline who have expired sessions")
@pass_obj
def cleanup_users(obj):
  app = create_app(obj["CONFIG"])
  with app.test_request_context():
    clean_users()

@cli.command("cleanup-users-loop", help="Continually send users offline who have expired sessions")
@pass_obj
def cleanup_users_loop(obj):
  app = create_app(obj["CONFIG"])
  with app.test_request_context():
    clean_users_loop()

@cli.command("backup-events", help="Back up the events logged")
@click.option("--backup-date", "-d", help="As 'YYYY-MM-DD'")
@click.option("--log-directory", "-l", default=".", help="e.g. '/var/log/prat'")
@pass_obj
def backup_events(obj, backup_date, log_directory):
  if backup_date is None:
    # start from yesterday if no date is given
    backup_date = datetime.datetime.combine(
      datetime.date.today() - datetime.timedelta(days=1),
      datetime.time()).strftime("%Y-%m-%d")
    backup_events(obj["CONFIG"], backup_date, log_directory)

if __name__ == "__main__":
  cli(obj={})
