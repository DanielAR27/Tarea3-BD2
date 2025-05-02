#!/bin/bash

# Salir inmediatamente si un comando falla
set -e

# Inicia la verificación general del estado del clúster
echo "==> Verificando el estado general del cluster..."

# Verifica el estado de cada ReplicaSet
echo "==> Estado de los ReplicaSets:"
docker exec -it mongocfg1 mongosh --eval 'rs.status()'
docker exec -it mongors1n1 mongosh --eval 'rs.status()'
docker exec -it mongors2n1 mongosh --eval 'rs.status()'
docker exec -it mongors3n1 mongosh --eval 'rs.status()'

# Verifica que el router mongos1 esté operativo
echo "==> Verificando el router mongos1 (ping)..."
docker exec -it mongos1 mongosh --eval 'db.adminCommand("ping")'

# Verifica que el router mongos2 esté operativo
echo "==> Verificando el router mongos2 (ping)..."
docker exec -it mongos2 mongosh --eval 'db.adminCommand("ping")'

# Verifica que el router mongos3 esté operativo
echo "==> Verificando el router mongos3 (ping)..."
docker exec -it mongos3 mongosh --eval 'db.adminCommand("ping")'

# Verifica los shards registrados en el clúster
echo "==> Verificando shards agregados:"
docker exec -it mongos1 mongosh --eval 'sh.status()'

# Conteo de documentos en cada colección de la base de datos travel_social
echo "==> Conteo de documentos por colección en travel_social:"
docker exec -it mongos1 mongosh --eval 'db.getSiblingDB("travel_social").usuarios.countDocuments()'
docker exec -it mongos1 mongosh --eval 'db.getSiblingDB("travel_social").posts.countDocuments()'
docker exec -it mongos1 mongosh --eval 'db.getSiblingDB("travel_social").comentarios.countDocuments()'

# Estadísticas generales de la base de datos travel_social
echo "==> Verificando distribución de datos (db.stats()):"
docker exec -it mongos1 mongosh --eval 'db.getSiblingDB("travel_social").stats()'

# Conteo de chunks por colección en el clúster
echo "==> Verificando chunks por colección:"
docker exec -it mongos1 mongosh --eval 'db.getSiblingDB("config").chunks.aggregate([{$group: {_id: "$ns", count: {$sum: 1}}}])'

# Finaliza el proceso de verificación
echo "==> Verificaciones completadas."
