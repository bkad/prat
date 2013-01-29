from chat.views.frontend import vendor_js_files
import uuid
from os import path
import hashlib
from fabric.operations import local
from fabric.contrib.project import rsync_project
from fabric.state import env

# bullshit where we need to unmonkey patch stuff gevent touched
import select
import threading
reload(select)
reload(threading)

env.use_ssh_config = True
if env.hosts == []:
  env.hosts = ["pratchat.com"]

config_template = """
from chat.config import DefaultConfig

class Config(DefaultConfig):
  DEBUG = False
  SECRET_KEY = "{secret}"
  COMPILED_JS = "{compiled_coffee_assets}"
  COMPILED_CSS = "{compiled_stylus_assets}"
  COMPILED_VENDOR_JS = "{compiled_vendor_js}"
"""

def compile_assets_file(command, extension):
  compiled = local(command, capture=True)
  fingerprint = hashlib.md5(compiled).hexdigest()
  target_filename = "/static/app_{1}_{0}.{1}".format(fingerprint, extension)
  with open("chat" + target_filename, "w") as target_file:
    target_file.write(compiled)
  return target_filename

def cleanup():
  files = ["chat/static/app_js_*.js", "chat/static/vendor_*.js", "chat/static/app_css_*.css", "config.py"]
  local("rm -f {0}".format(" ".join(files)))

def compile_vendor_js():
  vendor_files = ["chat/static/vendor/js/{0}".format(filename) for filename in vendor_js_files]
  minified = local("java -jar bin/compiler.jar --js {0}".format(" ".join(vendor_files)), capture=True)
  fingerprint = hashlib.md5(minified).hexdigest()
  target_filename = "/static/vendor_{0}.js".format(fingerprint)
  with open("chat" + target_filename, "w") as target_file:
    target_file.write(minified)
  return target_filename

def write_config():
  cleanup()

  coffee_command = "coffee -cp chat/assets/*.coffee | java -jar bin/compiler.jar"
  js_filename = compile_assets_file(coffee_command, "js")

  nib_path = path.join(path.dirname(path.abspath(__file__)), "node_modules/nib/lib/nib")
  stylus_command = "cat chat/assets/*.styl | stylus --use {0}".format(nib_path)
  css_filename = compile_assets_file(stylus_command, "css")
  vendor_js_filename = compile_vendor_js()

  secret = str(uuid.uuid4())

  compiled_config = config_template.format(secret=secret,
                                           compiled_coffee_assets=js_filename,
                                           compiled_stylus_assets=css_filename,
                                           compiled_vendor_js=vendor_js_filename)

  with open("config.py", "w") as config_file:
    config_file.write(compiled_config)

def rsync():
  rsync_project(remote_dir="/home/ubuntu", exclude=".git")

def deploy():
  write_config()
  rsync()
