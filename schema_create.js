db.createCollection("events", {capped: true, size: 1e7, autoIndexId: true});
db.createCollection("users", {capped: true, size:1e5, autoIndexId:true});