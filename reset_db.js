db.events.drop()
db.users.drop()
db.createCollection("events", {capped: true, size: 1e7, autoIndexId: true});
db.events.ensureIndex({ channel:1 })
db.createCollection("users", {autoIndexId:true});
