from flask import Blueprint, abort, current_app, g, make_response, request
from stylus import Stylus
import coffeescript
from os import path
import mimetypes

assets = Blueprint("assets", __name__)

@assets.before_request
def setup_stylus():
  g.css_compiler = Stylus(plugins={"nib":{}})

@assets.route("/<path:asset_path>")
def compiled_assets(asset_path):
  asset_path = path.join(current_app.config["COMPILED_ASSET_PATH"], asset_path)
  with current_app.open_resource(asset_path) as fp:
    file_contents = fp.read()
  if asset_path.endswith(".styl"):
    response = make_response(g.css_compiler.compile(file_contents))
    response.headers["Content-Type"] = "text/css"
  elif asset_path.endswith(".coffee"):
    response = make_response(coffeescript.compile(file_contents))
    response.headers["Content-Type"] = "application/javascript"
  else:
    response = make_response(file_contents)
    content_tuple = mimetypes.guess_type(asset_path)
    content_type = content_tuple[0] or "text/plain"
    response.headers["Content-Type"] = content_type
  return response
