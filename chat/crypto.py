import hashlib
from base64 import urlsafe_b64encode
from time import time

def check_request(request, secret):
  time_now = int(time())
  if time_now > int(request.args["expires"]):
    return False
  target_signature = generate_signature(secret, request.method, request.path, request.data, request.args)
  return target_signature == request.args["signature"]

def generate_signature(secret, method, path, body, params, exclude_params=["signature"]):
  body = "" if body is None else body
  signature = secret + method.upper() + path + prepare_query_string(params, exclude_params) + body
  return urlsafe_b64encode(hashlib.sha256(signature).digest())[:43]

def prepare_query_string(params, exclude_params):
  params = [(key, value) for key, value in params.iteritems() if key not in exclude_params]
  params.sort(key=lambda x: x[0])
  return "".join("%s=%s" % (key, value) for key, value in params)
