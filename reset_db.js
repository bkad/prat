db.events.drop()
db.users.drop()
db.createCollection("events", {capped: true, size: 1e7, autoIndexId: true});
db.createCollection("users", {autoIndexId:true});
