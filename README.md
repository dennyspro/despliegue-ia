Guía de Despliegue Automatizado: Clasificación de Imágenes (K8s)
Este documento describe el uso de las herramientas de automatización para desplegar el ecosistema de microservicios (Java y Python) en un clúster local de Kubernetes.

Requisitos del Sistema
Motor de Contenedores: Docker Desktop (Windows) o Docker Engine (Linux).

Orquestador: Minikube instalado y configurado.

Herramientas de CLI: kubectl y el SDK de Java (para el comando mvnw).

Estructura de Carpetas: El script debe residir en la raíz de la carpeta "modelo".

Ejecución en Entornos Windows (PowerShell)
El archivo desplegarWindows.ps1 gestiona todo el ciclo de vida del despliegue. Al ejecutarlo, el script elimina cualquier rastro previo antes de iniciar la nueva carga.

Inicie una terminal de PowerShell con privilegios de Administrador.

Acceda al directorio del proyecto:
cd E:\Descargas\modelo

Ejecute el script de despliegue:
.\desplegarWindows.ps1

Nota técnica: Si el sistema bloquea la ejecución, utilice el comando Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process antes de intentar el despliegue.

Ejecución en Entornos Linux (Bash)
El archivo desplegar.sh utiliza rutas relativas, permitiendo que el proyecto sea portable entre diferentes directorios del sistema de archivos.

Abra una terminal en la carpeta raíz del proyecto.

Otorgue permisos de ejecución al script (requerido solo la primera vez):
chmod +x desplegar.sh

Inicie el proceso de despliegue:
./desplegar.sh

Descripción del Flujo Automatizado
Ambos scripts ejecutan las siguientes fases de manera secuencial:

Limpieza de Recursos (Idempotencia): Se ejecuta kubectl delete sobre el archivo YAML para eliminar despliegues, servicios y pods previos. Esto garantiza que no existan conflictos de red o de versiones de imagen.

Configuración de Minikube: Se arranca el nodo utilizando espejos de repositorios alternativos (Alibaba Cloud) para mitigar bloqueos de proveedores de internet y errores de certificados SSL de Google.

Construcción Local: Se compila el proyecto Java mediante Maven y se generan las imágenes Docker para el servicio intermediario y el servicio de inteligencia artificial.

Carga de Imágenes (Bypass SSL): Se utiliza el comando minikube image load con el flag --overwrite. Esto transfiere las imágenes directamente al registro interno del clúster sin necesidad de conexión a internet, evitando errores de validación de certificados X.509.

Despliegue de Infraestructura: Se aplica la configuración de Kubernetes definida en el archivo proyecto.yaml.

Configuración Dinámica del Frontend: El script extrae la URL generada por el túnel de Minikube y la inyecta automáticamente en el archivo web-osos/script.js, actualizando el endpoint de la API.

Resolución de Problemas Comunes
Error de construcción en Java: Verifique que la estructura de carpetas sea servicio-intermediario/servicio-intermediario y que el archivo mvnw.cmd (Windows) o mvnw (Linux) esté presente.

Fallo en la carga de imagen de IA: Asegúrese de que el archivo Dockerfile se encuentre en la carpeta raíz (modelo) junto con el script de despliegue.

Túnel no responde: Si tras 15 segundos el script no detecta la URL, ejecute manualmente minikube service java-service --url para verificar el estado del servicio.