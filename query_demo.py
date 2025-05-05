from pymongo import MongoClient

# Conexión al clúster MongoDB a través de múltiples routers mongos para alta disponibilidad
client = MongoClient("mongodb://localhost:27019,localhost:27029,localhost:27039")
db = client["travel_social"]

def parse_id(posible_id):
    try:
        return int(posible_id)
    except ValueError:
        return posible_id

def obtener_posts_de_usuario(usuario_id):
    usuario_id = parse_id(usuario_id)
    return list(db.posts.find({"usuario_id": usuario_id}))

def obtener_comentarios_de_usuario(usuario_id):
    usuario_id = parse_id(usuario_id)
    return list(db.comentarios.find({"usuario_id": usuario_id}))

def obtener_comentarios_por_post(post_id):
    post_id = parse_id(post_id)
    return list(db.comentarios.find({"post_id": post_id}))

def buscar_usuario_por_nombre(nombre):
    return db.usuarios.find_one({"nombre_usuario": nombre})

def menu():
    while True:
        print("\n--- Menú de Búsqueda ---")
        print("1. Ver posts de un usuario")
        print("2. Ver comentarios de un usuario")
        print("3. Ver comentarios de un post")
        print("4. Buscar usuario por nombre")
        print("5. Salir")

        opcion = input("\nElija una opción: ")

        if opcion == "1":
            uid = input("ID del usuario: ")
            posts = obtener_posts_de_usuario(uid)
            for post in posts:
                print(post)
            print(f"\nEl usuario tiene {len(posts)} posts.")

        elif opcion == "2":
            uid = input("ID del usuario: ")
            comentarios = obtener_comentarios_de_usuario(uid)
            for com in comentarios:
                print(com)
            print(f"\nEl usuario tiene {len(comentarios)} comentarios.")

        elif opcion == "3":
            pid = input("ID del post: ")
            comentarios = obtener_comentarios_por_post(pid)
            for com in comentarios:
                print(com)
            print(f"\nEl post tiene {len(comentarios)} comentarios.")

        elif opcion == "4":
            nombre = input("Nombre de usuario: ")
            user = buscar_usuario_por_nombre(nombre)
            print("\nResultado de la búsqueda:")
            print(user)

        elif opcion == "5":
            break
        else:
            print("Opción inválida.")
            
if __name__ == "__main__":
    menu()
