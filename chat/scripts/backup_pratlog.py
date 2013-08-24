import argparse
import datetime
import json
from pymongo import MongoClient
import string
import sys

from ..config import DefaultConfig


def main(args):
    config = DefaultConfig()
    dbclient = MongoClient(host=config.MONGO_HOST,
                           port=config.MONGO_PORT,
                           tz_aware=True)
    db = dbclient[config.MONGO_DB_NAME]
    event_collection = db["events"]

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

def valid_filename(filename):
    valid_chars = "-_.() %s%s" % (string.ascii_letters, string.digits)
    filename = ''.join(c for c in filename if c in valid_chars)
    return filename

if __name__ == "__main__":
    yesterday = datetime.datetime.combine(
        datetime.date.today() - datetime.timedelta(days=1),
        datetime.time()).strftime("%Y-%m-%d")
    parser = argparse.ArgumentParser(description="Extract ip/header features")
    parser.add_argument("-d", "--backup-date", default=yesterday)
    args = vars(parser.parse_args())

    main(args)
