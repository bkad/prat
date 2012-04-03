db.createCollection("events", {capped: true, size: 1e7, autoIndexId: true});
