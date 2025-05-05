'''
Script para generar datos sintéticos para la red social de viajes
'''
import pymongo
import random
from faker import Faker
import time
from datetime import datetime, timedelta

# Configuración

# URI de conexión al clúster MongoDB utilizando múltiples routers mongos para alta disponibilidad y failover automático
MONGO_URI = "mongodb://mongos1:27017,mongos2:27017,mongos3:27017"
DB_NAME = "travel_social"

# Parámetros de generación
NUM_USUARIOS = 5000  
NUM_POSTS = 10000     
NUM_COMENTARIOS = 50000  

# Inicializar Faker en español
fake = Faker('es_ES')

# Destinos populares para hacer más realistas los posts
DESTINOS_POPULARES = [
    'Cancún', 'Barcelona', 'París', 'Nueva York', 'Tokio', 'Roma', 'Londres',
    'Ámsterdam', 'Río de Janeiro', 'Sídney', 'Ciudad de México', 'Berlín'
]

# URLs de imágenes de ejemplo
PLACEHOLDER_IMAGES = [
    'https://placehold.co/600x400?text=Playa',
    'https://placehold.co/600x400?text=Montaña',
    'https://placehold.co/600x400?text=Ciudad'
]

def conectar_mongodb():
    """Conectar a MongoDB con reintentos"""
    max_intentos = 5
    for intento in range(max_intentos):
        try:
            client = pymongo.MongoClient(MONGO_URI, serverSelectionTimeoutMS=10000)
            client.admin.command('ping')
            return client[DB_NAME]
        except Exception as e:
            print(f"Intento {intento + 1} de conexión fallido: {e}")
            if intento < max_intentos - 1:
                time.sleep(10)
            else:
                raise

def generar_usuario(id):
    """Generar datos de usuario"""
    nombre = fake.first_name()
    apellido = fake.last_name()
    
    return {
        "usuario_id": id,
        "nombre_usuario": f"{nombre.lower()}_{apellido.lower()}_{random.randint(1, 999)}",
        "correo_electronico": fake.email(),
        "contraseña": fake.password(),
        "biografia": fake.paragraph(nb_sentences=2)
    }

def generar_post(id, usuarios_ids):
    """Generar datos de post"""
    usuario_id = random.choice(usuarios_ids)
    destino = random.choice(DESTINOS_POPULARES)
    fotos = random.sample(PLACEHOLDER_IMAGES, k=random.randint(0, 3))
    
    return {
        "post_id": id,
        "usuario_id": usuario_id,
        "texto": fake.paragraph(nb_sentences=3),
        "destino": destino,
        "fotos_adjuntas": fotos,
        "fecha_publicacion": fake.date_time_between(start_date='-1y', end_date='now')
    }

def generar_comentario(id, posts_ids, usuarios_ids):
    """Generar datos de comentario"""
    return {
        "comentario_id": id,
        "post_id": random.choice(posts_ids),
        "usuario_id": random.choice(usuarios_ids),
        "texto": fake.paragraph(nb_sentences=2),
        "fecha_publicacion": fake.date_time_between(start_date='-6m', end_date='now')
    }

def insertar_datos():
    """Insertar datos en la base de datos"""
    db = conectar_mongodb()
    
    # Limpiar colecciones existentes
    db.usuarios.delete_many({})
    db.posts.delete_many({})
    db.comentarios.delete_many({})
    
    print("Colecciones limpiadas")
    
    # Insertar usuarios
    print(f"Generando {NUM_USUARIOS} usuarios...")
    usuarios = [generar_usuario(i) for i in range(1, NUM_USUARIOS + 1)]
    db.usuarios.insert_many(usuarios)
    print("Usuarios insertados")
    
    # Extraer IDs para referencias
    usuarios_ids = [u["usuario_id"] for u in usuarios]
    
    # Insertar posts
    print(f"Generando {NUM_POSTS} posts...")
    posts = [generar_post(i, usuarios_ids) for i in range(1, NUM_POSTS + 1)]
    db.posts.insert_many(posts)
    print("Posts insertados")
    
    # Extraer IDs de posts
    posts_ids = [p["post_id"] for p in posts]
    
    # Insertar comentarios (por lotes para evitar problemas de memoria)
    print(f"Generando {NUM_COMENTARIOS} comentarios...")
    BATCH_SIZE = 1000
    
    for i in range(0, NUM_COMENTARIOS, BATCH_SIZE):
        end = min(i + BATCH_SIZE, NUM_COMENTARIOS)
        comentarios_batch = [generar_comentario(j, posts_ids, usuarios_ids) 
                           for j in range(i + 1, end + 1)]
        db.comentarios.insert_many(comentarios_batch)
        print(f"Insertados {end} de {NUM_COMENTARIOS} comentarios")
    
    # Verificar conteo
    print("\nVerificación final:")
    print(f"Usuarios: {db.usuarios.count_documents({})}")
    print(f"Posts: {db.posts.count_documents({})}")
    print(f"Comentarios: {db.comentarios.count_documents({})}")

if __name__ == "__main__":
    insertar_datos()