class DefaultConfig(object):
  """Default configuration for chat app"""
  DEBUG = True
  SECRET_KEY = "secret"
  MONGO_HOST = "127.0.0.1"
  MONGO_PORT = 27017
  MONGO_DB_NAME = "oochat"
  COMPILED_ASSET_PATH = "assets"
