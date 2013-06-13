# -*- coding: utf-8 -*-
"""
  chat.scripts.util
  ~~~~~~~~~~~~~~~~~~~~~~~~~

  Common utilities for prat scripts

"""

from __future__ import print_function
from sys import stderr, argv
from werkzeug.utils import import_string, ImportStringError
from ..config import DefaultConfig

def get_config_or_exit():
  if len(argv) == 2:
    try:
      config = import_string(argv[1])
    except ImportStringError:
      print("Invalid import string: {0}".format(argv[1]), file=stderr)
      exit()
  else:
    config = DefaultConfig
  return config
