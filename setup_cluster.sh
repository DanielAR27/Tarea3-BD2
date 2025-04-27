#!/bin/bash

# Salir inmediatamente si un comando falla
set -e

# Levanta todos los contenedores necesarios para el clúster de MongoDB
echo "==> Levantando contenedores MongoDB..."
docker-compose up -d mongors1n1 mongors1n2 mongors1n3 mongors2n1 mongors2n2 mongors2n3 mongors3n1 mongors3n2 mongors3n3 mongocfg1 mongocfg2 mongocfg3 mongos1

# Espera para dar tiempo a que los servicios arranquen
echo "==> Esperando 15 segundos para que todos arranquen..."
sleep 15

# Inicializa el ReplicaSet de los Config Servers
echo "==> Inicializando ReplicaSet de Config Servers..."
docker exec -it mongocfg1 mongosh --eval 'rs.initiate({_id: "mongors1conf", configsvr: true, members: [{ _id: 0, host: "mongocfg1:27017" },{ _id: 1, host: "mongocfg2:27017" },{ _id: 2, host: "mongocfg3:27017" }]})'

# Inicializa el ReplicaSet del Shard 1
echo "==> Inicializando ReplicaSet de Shard 1..."
docker exec -it mongors1n1 mongosh --eval 'rs.initiate({_id: "mongors1", members: [{ _id: 0, host: "mongors1n1:27017" },{ _id: 1, host: "mongors1n2:27017" },{ _id: 2, host: "mongors1n3:27017" }]})'

# Inicializa el ReplicaSet del Shard 2
echo "==> Inicializando ReplicaSet de Shard 2..."
docker exec -it mongors2n1 mongosh --eval 'rs.initiate({_id: "mongors2", members: [{ _id: 0, host: "mongors2n1:27017" },{ _id: 1, host: "mongors2n2:27017" },{ _id: 2, host: "mongors2n3:27017" }]})'

# Inicializa el ReplicaSet del Shard 3
echo "==> Inicializando ReplicaSet de Shard 3..."
docker exec -it mongors3n1 mongosh --eval 'rs.initiate({_id: "mongors3", members: [{ _id: 0, host: "mongors3n1:27017" },{ _id: 1, host: "mongors3n2:27017" },{ _id: 2, host: "mongors3n3:27017" }]})'

# Espera para asegurar que los ReplicaSets estén estables
echo "==> Esperando 30 segundos para que los ReplicaSets se estabilicen..."
sleep 30

# Verifica la conexión al router mongos1
echo "==> Verificando mongos1 (router)..."
docker exec -it mongos1 mongosh --eval 'db.adminCommand("ping")'

# Agrega los shards al clúster a través de mongos1
echo "==> Agregando Shards al Cluster..."
docker exec -it mongos1 mongosh --eval 'sh.addShard("mongors1/mongors1n1:27017,mongors1n2:27017,mongors1n3:27017")'
docker exec -it mongos1 mongosh --eval 'sh.addShard("mongors2/mongors2n1:27017,mongors2n2:27017,mongors2n3:27017")'
docker exec -it mongos1 mongosh --eval 'sh.addShard("mongors3/mongors3n1:27017,mongors3n2:27017,mongors3n3:27017")'

# Habilita el sharding en la base de datos "travel_social"
echo "==> Habilitando Sharding en la base de datos travel_social..."
docker exec -it mongos1 mongosh --eval 'sh.enableSharding("travel_social")'

# Crea las colecciones y configura el sharding en cada una
echo "==> Creando colecciones y configurando sharding..."

# Usuarios
docker exec -it mongos1 mongosh --eval 'db.getSiblingDB("travel_social").createCollection("usuarios")'
docker exec -it mongos1 mongosh --eval 'db.getSiblingDB("travel_social").usuarios.createIndex({ "usuario_id": 1 })'
docker exec -it mongos1 mongosh --eval 'sh.shardCollection("travel_social.usuarios", { "usuario_id": "hashed" })'

# Posts
docker exec -it mongos1 mongosh --eval 'db.getSiblingDB("travel_social").createCollection("posts")'
docker exec -it mongos1 mongosh --eval 'db.getSiblingDB("travel_social").posts.createIndex({ "usuario_id": 1 })'
docker exec -it mongos1 mongosh --eval 'db.getSiblingDB("travel_social").posts.createIndex({ "fecha_publicacion": 1 })'
docker exec -it mongos1 mongosh --eval 'sh.shardCollection("travel_social.posts", { "usuario_id": "hashed" })'

# Comentarios
docker exec -it mongos1 mongosh --eval 'db.getSiblingDB("travel_social").createCollection("comentarios")'
docker exec -it mongos1 mongosh --eval 'db.getSiblingDB("travel_social").comentarios.createIndex({ "post_id": 1 })'
docker exec -it mongos1 mongosh --eval 'db.getSiblingDB("travel_social").comentarios.createIndex({ "usuario_id": 1 })'
docker exec -it mongos1 mongosh --eval 'sh.shardCollection("travel_social.comentarios", { "usuario_id": "hashed" })'

# Finaliza la configuración
echo "==> Cluster configurado exitosamente."
