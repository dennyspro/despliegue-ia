#!/bin/bash

# =========================================================================
# SCRIPT DE DESPLIEGUE - RUTAS RELATIVAS (VERSION LINUX)
# =========================================================================

# 1. Detectar la ruta donde se encuentra este script
BASE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# Definicion de rutas relativas
PATH_JAVA="$BASE_DIR/servicio-intermediario/servicio-intermediario"
PATH_PYTHON="$BASE_DIR" # La IA esta en la misma carpeta que el script
YAML_PATH="$PATH_JAVA/proyecto.yaml"
JS_PATH="$BASE_DIR/web-osos/script.js"

echo -e "\n\e[33m--- 1. LIMPIEZA TOTAL ---\e[0m"

echo -e "\n\e[33m--- 1. Eliminando recursos de Kubernetes (Pods, Services, etc.) ---\e[0m"
if [ -f "$YAML_PATH" ]; then
    kubectl delete -f "$YAML_PATH" --ignore-not-found
else
    echo "Aviso: No se encontro el YAML en $YAML_PATH, saltando borrado de recursos."
fi

echo -e "\n\e[36m--- 2. Eliminando imagenes del cache interno de Minikube ---\e[0m"
# Esto libera espacio dentro de la maquina virtual de Minikube
minikube image rm java-service:latest 2>/dev/null
minikube image rm ai-service:latest 2>/dev/null

echo -e "\n\e[36m--- 3. Eliminando imagenes locales de Docker (Host) ---\e[0m"
# Esto borra las imagenes que construiste en tu sistema Linux
docker rmi -f java-service:latest ai-service:latest 2>/dev/null


# Borramos el despliegue anterior usando el YAML que esta en la carpeta de Java
kubectl delete -f "$YAML_PATH" --ignore-not-found

echo -e "\n\e[35m--- 2. COMPILANDO JAVA ---\e[0m"
if [ -f "$PATH_JAVA/mvnw" ]; then
    cd "$PATH_JAVA"
    chmod +x mvnw # Aseguramos permisos de ejecucion para Maven
    ./mvnw clean package -DskipTests
    docker build -t java-service:latest .
else
    echo -e "\e[31mError: No se encontro mvnw en $PATH_JAVA\e[0m"
    exit 1
fi

echo -e "\n\e[35m--- 3. CONSTRUYENDO PYTHON ---\e[0m"
cd "$PATH_PYTHON"
if [ -f "Dockerfile" ]; then
    docker build -t ai-service:latest .
else
    echo -e "\e[33mAdvertencia: No se encontro Dockerfile de la IA en $PATH_PYTHON\e[0m"
fi

echo -e "\n\e[34m--- 4. CARGA LOCAL A MINIKUBE ---\e[0m"
minikube image load java-service:latest --overwrite
# Solo cargamos la IA si la imagen se construyo con exito
if [[ "$(docker images -q ai-service:latest 2> /dev/null)" != "" ]]; then
    minikube image load ai-service:latest --overwrite
fi

echo -e "\n\e[34m--- 5. DESPLEGANDO EN KUBERNETES ---\e[0m"
kubectl apply -f "$YAML_PATH"

echo -e "\n\e[32m--- 6. GENERANDO TUNEL Y WEB ---\e[0m"
sleep 15
# Obtenemos la URL y limpiamos caracteres extraños
URL=$(minikube service java-service --url | head -n 1 | xargs)

if [[ $URL == http* ]]; then
    # Actualizamos el script.js usando 'sed' (el editor de texto de consola)
    sed -i "s|const URL_API = \".*\"|const URL_API = \"$URL/api/v1/classify\"|g" "$JS_PATH"
    
    echo -e "\e[32m--- TODO LISTO. URL detectada: $URL ---\e[0m"
    
    # Intentar abrir el navegador en Linux
    xdg-open "$BASE_DIR/web-osos/index.html" || echo "Abre manualmente: $BASE_DIR/web-osos/index.html"
else
    echo -e "\e[31mError: El tunel no genero una URL valida.\e[0m"
fi