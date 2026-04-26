    mongodb-shard-${SHARD_IDX}-${REP_IDX}:
      container_name: mongodb-shard-${SHARD_IDX}-${REP_IDX}
      image: dh-mirror.gitverse.ru/mongo:latest
      command:
        [
          "--shardsvr",
          "--replSet",
          "bf-shard-${SHARD_IDX}",
          "--bind_ip_all",
          "--port",
          "27017"
        ]
      depends_on:
        - mongodb-configsvr
      networks:
        - bf-network
      volumes:
        - mongodb_shard_${SHARD_IDX}_${REP_IDX}_container:/data/db
      healthcheck:
        test: [ "CMD", "mongo", "--eval", "db.adminCommand('ping')" ]
        interval: 5s
        start_period: 10s
