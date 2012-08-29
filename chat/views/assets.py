from flask import Blueprint, abort, current_app, g, make_response, request, _app_ctx_stack, url_for
from werkzeug.local import LocalProxy
from stylus import Stylus
import coffeescript
from os import path
import mimetypes
from email.utils import formatdate
from collections import defaultdict, namedtuple
import hashlib

assets = Blueprint("assets", __name__)

def get_assets_cache():
  context = _app_ctx_stack.top
  cache = getattr(context, "prat_assets_cache", None)
  if cache is None:
    cache = context.prat_assets_cache = defaultdict(lambda: None)
  return cache

assets_cache = LocalProxy(get_assets_cache)
CompiledAsset = namedtuple("CompiledAsset", "content fingerprint last_modified content_type")

def get_stylus_compiler():
  context = _app_ctx_stack.top
  compiler = getattr(context, "prat_stylus_compiler", None)
  if compiler is None:
    compiler = context.prat_stylus_compiler = Stylus(plugins={ "nib": {} })
  return compiler

stylus_compiler = LocalProxy(get_stylus_compiler)


@assets.route("/<path:asset_path>")
def compiled_assets(asset_path):
  try:
    file_path, file_extension = asset_path.rsplit(".", 1)
    file_path, fingerprint = asset_path.rsplit("-", 1)
  except ValueError:
    abort(404)

  asset_path = file_path + "." + file_extension
  try:
    compiled_asset = get_cached_asset(asset_path)
  except OSError:
    abort(404)

  response = make_response(compiled_asset.content)
  response.headers["Last-Modified"] = formatdate(compiled_asset.last_modified)
  response.headers["Content-Type"] = compiled_asset.content_type
  return response

def get_filesystem_paths(asset_path):
  relative_path = path.join(current_app.config["COMPILED_ASSET_PATH"], asset_path)
  absolute_path = path.join(current_app.root_path, relative_path)
  return (relative_path, absolute_path)

def get_cached_asset(asset_path):
  relative_path, absolute_path = get_filesystem_paths(asset_path)
  last_modified = path.getmtime(absolute_path)
  cached_asset = assets_cache[asset_path]
  if cached_asset is not None and last_modified <= cached_asset.last_modified:
    return cached_asset
  compiled_asset = compile_asset(asset_path)
  assets_cache[asset_path] = compiled_asset
  return compiled_asset

def compile_asset(asset_path):
  relative_path, absolute_path = get_filesystem_paths(asset_path)
  with current_app.open_resource(relative_path) as fp:
    file_contents = fp.read()
  if asset_path.endswith(".styl"):
    content = stylus_compiler.compile(file_contents)
    content_type = "text/css"
  elif asset_path.endswith(".coffee"):
    content = coffeescript.compile(file_contents)
    content_type = "application/javascript"
  else:
    content = file_contents
    content_tuple = mimetypes.guess_type(asset_path)
    content_type = content_tuple[0] or "text/plain"
  fingerprint = hashlib.md5(content).hexdigest()
  last_modified = path.getmtime(absolute_path)
  return CompiledAsset(content, fingerprint, last_modified, content_type)

def asset_url(asset_path):
  fingerprint = get_cached_asset(asset_path).fingerprint
  file_path, file_extension = asset_path.rsplit(".")
  fingerprinted_path = file_path + "-" + fingerprint + "." + file_extension
  return url_for("assets.compiled_assets", asset_path=fingerprinted_path)
