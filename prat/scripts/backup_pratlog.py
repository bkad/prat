"""
Backup script to backup the specified days worth of pratlogs.
If no arguments are given, the default config and yesterday's pratlog are
backed up into the current directory
"""
import argparse
import datetime
import json
import os
from pymongo import MongoClient
import string
import sys

from ..config import Config
from .utils import get_config

def backup_events(config, date, log_directory):
    event_collection = mongo_collection(config.MONGO_HOST, config.MONGO_PORT,
                                        config.MONGO_DB_NAME, "events")
    backup_date = datetime.datetime.strptime(date, "%Y-%m-%d")
    next_day = backup_date + datetime.timedelta(days=1)

    days_events = event_collection.find({"datetime": {"$gte": backup_date,
                                                      "$lt": next_day}})
    channel_files = {}
    for event in days_events:
        channel = event["channel"]
        if channel not in channel_files:
            filename = "pratlog.{0}.{1}.txt".format(valid_filename(channel),
                                                    backup_date.strftime("%Y-%m-%d"))
            output_file = open(os.path.join(log_directory, filename), "w")
            channel_files[channel] = output_file
        else:
            output_file = channel_files[channel]

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
