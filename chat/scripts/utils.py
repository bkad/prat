# -*- coding: utf-8 -*-
"""
  chat.scripts.util
  ~~~~~~~~~~~~~~~~~~~~~~~~~

  Common utilities for prat scripts

"""

from sys import argv
from ..config import Config

def get_config_from_argv():
  return get_config(argv[1] if len(argv) > 1 else None)

def get_config_filename_from_argv():
  return argv[1] if len(argv) > 1 else None

def get_config(filename=None):
  return Config.import_toml(filename) if filename else Config()

if __name__ == "__main__":
  get_config_from_argv()
