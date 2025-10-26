#!/bin/bash
set -e

echo "Waiting for MongoDB instances to be ready..."
sleep 10

echo "Initializing Config Server Replica Set..."
mongosh --host configSrv:27017 --eval '
rs.initiate({
  _id: "config_server",
  configsvr: true,
  members: [{ _id: 0, host: "configSrv:27017" }]
})
' || echo "Config server already initialized"

echo "Waiting for config server to elect primary..."
sleep 5

echo "Initializing Shard 1 Replica Set..."
mongosh --host mongo-shard1:27018 --eval '
rs.initiate({
  _id: "shard1",
  members: [
    { _id: 0, host: "mongo-shard1:27018" },
    { _id: 1, host: "mongo-shard1-repl1:27021" },
    { _id: 2, host: "mongo-shard1-repl2:27022" }
  ]
  
})
' || echo "Shard 1 already initialized"

echo "Initializing Shard 2 Replica Set..."
mongosh --host mongo-shard2:27019 --eval '
rs.initiate({
  _id: "shard2",
  members: [
    { _id: 0, host: "mongo-shard2:27019" },
    { _id: 1, host: "mongo-shard2-repl1:27024" },
    { _id: 2, host: "mongo-shard2-repl2:27025" }
  ]
})
' || echo "Shard 2 already initialized"

echo "Waiting for replica sets to elect primaries..."
sleep 10

echo "Adding Shards to Cluster..."
mongosh --host mongos_router:27020 --eval '
sh.addShard("shard1/mongo-shard1:27018");
sh.addShard("shard2/mongo-shard2:27019");
' || echo "Shards already added"

echo "Enabling Sharding on Database..."
mongosh --host mongos_router:27020 --eval '
sh.enableSharding("somedb");
' || echo "Database already sharded"

echo "Creating Sharded Collection..."
mongosh --host mongos_router:27020 --eval '
sh.shardCollection("somedb.helloDoc", { name: "hashed" });
' || echo "Collection already sharded"

echo "Inserting Sample Data..."
mongosh --host mongos_router:27020 --eval '
const db = db.getSiblingDB("somedb");
for (let i = 0; i < 1000; i++) {
  db.helloDoc.insertOne({
    age: Math.floor(Math.random() * 100),
    name: "name" + i
  });
}
print("Inserted 1000 documents");
print("Total documents: " + db.helloDoc.countDocuments());
' || echo "Sample data already exists"

echo "MongoDB Sharded Cluster initialization complete!"
