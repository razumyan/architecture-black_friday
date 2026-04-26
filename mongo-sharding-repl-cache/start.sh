#!/bin/bash

docker compose down -v

SHARDS=2
REPLICAS=3

echo "services:" > generated-sharding.yaml

SHARD_MEMBERS=( "none" )
ADD_SHARDING=()
for ((SHARD_IDX = 1; SHARD_IDX <= $SHARDS; SHARD_IDX++)); do
  MEMBERS=()
  for ((REP_IDX = 1; REP_IDX <= $REPLICAS; REP_IDX++)); do
    MEMBERS+=( "{ _id : ${REP_IDX}, host : 'mongodb-shard-${SHARD_IDX}-${REP_IDX}:27017' }" )
    ADD_SHARD_SCRIPT="sh.addShard('bf-shard-${SHARD_IDX}/mongodb-shard-${SHARD_IDX}-${REP_IDX}:27017');"
    ADD_SHARDING+=("$ADD_SHARD_SCRIPT")
    export SHARD_IDX
    export REP_IDX
    envsubst < mongdb-sharding.yaml.tpl >> generated-sharding.yaml
  done;
  JOINED_MEMBERS=$(IFS=', '; echo "${MEMBERS[*]}")
  SHARD_MEMBERS+=( "$JOINED_MEMBERS" )
done;

echo "volumes:" >> generated-sharding.yaml
for ((SHARD_IDX = 1; SHARD_IDX <= $SHARDS; SHARD_IDX++)); do
  for ((REP_IDX = 1; REP_IDX <= $REPLICAS; REP_IDX++)); do
    echo "  mongodb_shard_${SHARD_IDX}_${REP_IDX}_container:" >> generated-sharding.yaml
  done;
done;

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

for ((SHARD_IDX = 1; SHARD_IDX <= $SHARDS; SHARD_IDX++)); do
  for ((REP_IDX = 1; REP_IDX <= $REPLICAS; REP_IDX++)); do
docker compose exec -T mongodb-shard-$SHARD_IDX-$REP_IDX mongosh <<EOF
  rs.initiate(
    {
      _id : "bf-shard-$SHARD_IDX",
      members: [
        ${SHARD_MEMBERS[$SHARD_IDX]}
      ]
    }
  )
EOF
  done;
done;

ADD_SHARDING_SCRIPT=$(IFS=$'\n'; echo "${ADD_SHARDING[*]}")

docker compose exec -T mongodb-router mongosh <<EOF
$ADD_SHARDING_SCRIPT

sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name":  "hashed" });
EOF
