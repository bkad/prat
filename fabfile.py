import uuid
from os import path
import hashlib
from fabric.operations import local

config_template = """
from chat.config import DefaultConfig

class Config(DefaultConfig):
  DEBUG = False
  SECRET_KEY = "{secret}"
  COMPILED_JS = "{compiled_coffee_assets}"
  COMPILED_CSS = "{compiled_stylus_assets}"
"""

def compile_assets_file(command, extension):
  compiled = local(command, capture=True)
  fingerprint = hashlib.md5(compiled).hexdigest()
  target_filename = "/static/app_{0}.{1}".format(fingerprint, extension)
  with open("chat" + target_filename, "w") as target_file:
    target_file.write(compiled)
  return target_filename

def cleanup():
  local("rm -f chat/static/app_*")
  local("rm -f config.py")

def write_config():
  cleanup()

  coffee_command = "coffee -cp chat/assets/*.coffee | java -jar bin/compiler.jar"
  js_filename = compile_assets_file(coffee_command, "js")

  nib_path = path.join(path.dirname(path.abspath(__file__)), "node_modules/nib/lib/nib")
  stylus_command = "cat chat/assets/*.styl | stylus --use {0}".format(nib_path)
  css_filename = compile_assets_file(stylus_command, "css")

  secret = str(uuid.uuid4())

  compiled_config = config_template.format(secret=secret,
                                           compiled_coffee_assets=js_filename,
                                           compiled_stylus_assets=css_filename)

  with open("config.py", "w") as config_file:
    config_file.write(compiled_config)
