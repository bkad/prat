supported browsers:
  chrome, and chrome only

system package prerequisites:
  zeromq, mongodb, redis

to install python requirements (i recommend use of virtualenv)

`pip install -r requirements.txt`

to install nodejs requirements (using local package.json file)

`npm install`

to create mongo capped collection (while mongod is running)

`mongo prat reset_db.js`

to install javascript/css dependencies

`bower install`

running the servers:

`python -m chat.scripts.event_server`
`python run_server.py`
and make sure mongod and redis-server is running
