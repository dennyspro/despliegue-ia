#!/bin/bash

export PATH=$PATH:/usr/local/bin:/usr/bin:/bin:/snap/bin:$HOME/.local/bin
BASE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# =========================================================================
# PARCHE DE PERMISOS: Recupera la propiedad de los archivos si root los bloqueó
# =========================================================================
echo -e "\e[33m--- VERIFICANDO PERMISOS DE CARPETA ---\e[0m"
sudo chown -R $USER:$USER "$BASE_DIR"

# Definición de rutas
PATH_JAVA="$BASE_DIR/servicio-intermediario/servicio-intermediario"
PATH_PYTHON="$BASE_DIR" 
YAML_PATH="$PATH_JAVA/proyecto.yaml"
# Corregida la ruta de la carpeta web basándonos en tu terminal
JS_PATH="$BASE_DIR/web/script.js" 

ejecutar_todo() {
    echo -e "\n\e[33m--- 1. LIMPIEZA DE RECURSOS ---\e[0m"
    kubectl delete -f "$YAML_PATH" --ignore-not-found 2>/dev/null

    echo -e "\n\e[35m--- 2. CONSTRUYENDO IMAGEN JAVA (Docker Interno) ---\e[0m"
    cd "$PATH_JAVA"
    docker build -t java-service:latest .

    echo -e "\n\e[35m--- 3. CONSTRUYENDO IMAGEN IA (Python) ---\e[0m"
    cd "$PATH_PYTHON"
    docker build -t ai-service:latest .

    echo -e "\n\e[34m--- 4. CARGA DE IMÁGENES A MINIKUBE ---\e[0m"
    echo "Esto puede tardar un poco, no cierres la terminal..."
    minikube image load java-service:latest --overwrite
    minikube image load ai-service:latest --overwrite

    echo -e "\n\e[34m--- 5. DESPLEGANDO EN KUBERNETES ---\e[0m"
    kubectl apply -f "$YAML_PATH" || kubectl apply -f "$YAML_PATH" --validate=false

    echo -e "\n\e[32m--- 6. GENERANDO TUNEL Y WEB ---\e[0m"
    echo "Esperando que los Pods se estabilicen (20s)..."
    sleep 20
    
    URL=$(minikube service java-service --url | head -n 1 | xargs)

    if [[ $URL == http* ]]; then
        # Ahora sed tendrá permisos gracias al chown inicial
        sed -i "s|const URL_API = \".*\"|const URL_API = \"$URL/api/v1/classify\"|g" "$JS_PATH"
        echo -e "\e[32m--- ✅ DESPLIEGUE EXITOSO ---\e[0m"
        echo -e "\e[32m--- URL: $URL ---\e[0m"
        xdg-open "$BASE_DIR/web/index.html" 2>/dev/null || echo "Abre: $BASE_DIR/web/index.html"
    else
        echo -e "\e[31mError: No se pudo conectar con el servicio. Prueba ejecutar: minikube service java-service --url\e[0m"
    fi
    read -p "Presiona Enter para cerrar..."
}

# Verificación de permisos y ejecución
if [ "$EUID" -eq 0 ]; then
    echo "Por favor, corre el script sin sudo."
    exit 1
fi

if groups $USER | grep -q "\bdocker\b"; then
    ejecutar_todo
else
    sudo usermod -aG docker $USER
    exec sg docker "$0"
fi
