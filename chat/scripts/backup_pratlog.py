import argparse
import datetime
import json
from pymongo import MongoClient
import string
import sys

from ..config import DefaultConfig
from .utils import get_config

def main(args):
    config = DefaultConfig()
    if args["config"] is not None:
        config = get_config(args["config"])
        if (config is None):
            sys.exit("Could not load config")

    event_collection = mongo_collection(config.MONGO_HOST, config.MONGO_PORT,
                                        config.MONGO_DB_NAME, "events")
    backup_date = datetime.datetime.strptime(args["backup_date"], "%Y-%m-%d")
    next_day = backup_date + datetime.timedelta(days=1)

    days_events = event_collection.find({"datetime": {"$gte": backup_date,
                                                      "$lt": next_day}})
    channel_files = {}
    for event in days_events:
        channel = event["channel"]
        filename = "pratlog.{0}.{1}.txt".format(valid_filename(channel), backup_date.strftime("%Y-%m-%d"))
        output_file = channel_files.setdefault(channel, open(filename, "w"))

        print >> output_file, "{2} {0} <{1}>: {3}".format(
            event["author"], event["email"],
            event["datetime"].strftime("%Y-%m-%d %H:%M:%S"),
            event["message"])

    for file_handle in channel_files.values():
        file_handle.close()

def mongo_collection(host, port, db, collection_name):
    dbclient = MongoClient(host=host,
                           port=port,
                           tz_aware=True)
    db = dbclient[db]
    return db[collection_name]

def valid_filename(filename):
    """Strips out any characters that aren't ascii letters or digits"""
    valid_chars = "-_.() {0}{1}".format(string.ascii_letters, string.digits)
    filename = ''.join(c for c in filename if c in valid_chars)
    return filename

if __name__ == "__main__":
    yesterday = datetime.datetime.combine(
        datetime.date.today() - datetime.timedelta(days=1),
        datetime.time()).strftime("%Y-%m-%d")
    parser = argparse.ArgumentParser(description="Extract ip/header features")
    parser.add_argument("-d", "--backup-date", default=yesterday)
    parser.add_argument("-c", "--config", default=None,
                        help="eg. 'config.MyConfig'")
    args = vars(parser.parse_args())

    main(args)
