db.events.drop()
db.users.drop()
db.channels.drop()
db.createCollection("events", {capped: true, size: 1e7, autoIndexId: true});
db.createCollection("users", {autoIndexId:true});
db.createCollection("channels", {autoIndexId: true});
db.channels.save({"name":"general", "users":{}});
db.channels.save({"name":"Backlot", "users":{}});
db.channels.save({"name":"OOSL", "users":{}});
