from chat.views.frontend import vendor_js_files, coffee_files, write_main_template
from os import path
import hashlib
from fabric.operations import local
from fabric.contrib.project import rsync_project
from fabric.state import env
from chat import create_app
import imp

# bullshit where we need to unmonkey patch stuff gevent touched
import select
import threading
imp.reload(select)
imp.reload(threading)

env.use_ssh_config = True
if env.hosts == []:
  env.hosts = ["pratchat.com"]

config_template = """
from chat.config import DefaultConfig
import os

class Config(DefaultConfig):
  DEBUG = False
  SECRET_KEY = os.environ.get("PRAT_SECRET", "seeeecrets")
  COMPILED_JS = "{compiled_coffee_assets}"
  COMPILED_CSS = "{compiled_stylus_assets}"
  REWRITE_MAIN_TEMPLATE = False
"""

def write_asset_contents(contents, extension):
  fingerprint = hashlib.md5(contents).hexdigest()
  target_filename = "/static/app_{1}_{0}.{1}".format(fingerprint, extension)
  with open("chat" + target_filename, "w") as target_file:
    target_file.write(contents)
  return target_filename

def compile_assets_file(command, extension):
  compiled = local(command, capture=True)
  return write_asset_contents(compiled, extension)

def cleanup():
  files = ["chat/static/app_js_*.js",
           "chat/static/vendor_*.js",
           "chat/static/app_css_*.css",
           "config.py",
           "chat/templates/index.htmljinja",
          ]
  local("rm -f {0}".format(" ".join(files)))

  # Remove all *.pyc files recursively
  local("find . -name \"*.pyc\" -exec rm -rf {} \\;")

def compile_vendor_js():
  vendor_files = ["chat/static/vendor/js/{0}".format(filename) for filename in vendor_js_files]
  return local("./node_modules/.bin/uglifyjs {0} -c".format(" ".join(vendor_files)), capture=True)

def write_config():
  cleanup()

  vendor_js = compile_vendor_js()

  coffee_paths = " ".join(["chat/assets/{0}.coffee".format(file_path) for file_path in coffee_files])
  coffee_command = "coffee -cp {0} | ./node_modules/.bin/uglifyjs - -c -m".format(coffee_paths)
  coffee_js = local(coffee_command, capture=True)

  all_js = vendor_js + coffee_js
  js_filename = write_asset_contents(all_js, "js")

  nib_path = path.join(path.dirname(path.abspath(__file__)), "node_modules/nib/lib/nib")
  stylus_command = "cat chat/assets/*.styl | stylus --use {0}".format(nib_path)
  css_filename = compile_assets_file(stylus_command, "css")

  compiled_config = config_template.format(compiled_coffee_assets=js_filename,
                                           compiled_stylus_assets=css_filename)

  with open("config.py", "w") as config_file:
    config_file.write(compiled_config)

def precompile_template():
  # Yes, we're importing a module we just wrote.
  config_module = imp.load_module("config", *imp.find_module("config", ["./"]))
  app = create_app(config_module.Config)
  with app.test_request_context():
    write_main_template()

def rsync():
  rsync_project(remote_dir="/home/ubuntu", exclude=".git")

def deploy():
  write_config()
  precompile_template()
  rsync()
