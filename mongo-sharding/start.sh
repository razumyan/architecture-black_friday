#!/bin/bash

docker compose down -v
docker compose up -d --wait

docker compose exec -T mongodb-configsvr mongosh <<EOF
rs.initiate(
  {
    _id : "config_rs",
    configsvr: true,
    members: [
      { _id : 0, host : "mongodb-configsvr:27017" },
    ]
  }
)
EOF

docker compose exec -T mongodb-shard-1 mongosh <<EOF
rs.initiate(
  {
    _id : "bf-shard-1",
    members: [
      { _id : 0, host : "mongodb-shard-1:27017" },
    ]
  }
)
EOF

docker compose exec -T mongodb-shard-2 mongosh <<EOF
rs.initiate(
  {
    _id : "bf-shard-2",
    members: [
      { _id : 0, host : "mongodb-shard-2:27017" },
    ]
  }
)
EOF

docker compose exec -T mongodb-router mongosh <<EOF
sh.addShard("bf-shard-1/mongodb-shard-1:27017");
sh.addShard("bf-shard-2/mongodb-shard-2:27017");

sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name":  "hashed" });
EOF
