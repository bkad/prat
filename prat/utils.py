#!/usr/bin/env python
# -*- coding: utf-8 -*-

import ujson as json
from flask import Response

def jsonify(arg):
  return Response(json.dumps(arg), "application/json")

