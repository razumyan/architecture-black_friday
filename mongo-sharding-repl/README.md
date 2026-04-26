# mongo-sharding

## Как запустить

Запускаем mongodb и приложение

```shell
./start.sh
```

Заполняем mongodb данными

```shell
./scripts/mongo-init.sh
```

Проверка количества данных на шарде/реплике

```shell
docker compose exec -T mongodb-shard-2-3 mongosh <<EOF
use somedb;
db.helloDoc.countDocuments();
EOF
```
