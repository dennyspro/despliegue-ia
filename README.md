# Guía de Despliegue Automatizado: Clasificación de Imágenes (K8s)

Este ecosistema de microservicios (Java y Python) está diseñado para desplegarse de forma totalmente automática en un clúster local de Kubernetes (Minikube). 

---

## 🛠️ Requisitos del Sistema

### Para entornos Linux (Debian/Ubuntu)
Debes tener instaladas las siguientes herramientas de CLI y asegurarte de que tu usuario pertenece al grupo de Docker:
* **Docker Engine:** Motor de contenedores (sudo apt install docker.io).
* **Minikube:** Orquestador local.
* **Kubectl:** Cliente de Kubernetes.
* **Git:** Para clonar el repositorio.

### Para entornos Windows
* **Docker Desktop:** Configurado para usar contenedores de Linux (WSL2 recomendado).
* **Minikube:** Instalado (ej. via winget install minikube).
* **Kubectl:** Instalado y agregado al PATH (ej. via winget install Kubernetes.kubectl).
* **PowerShell:** Ejecutado en modo Administrador.

---

## 🚀 Ejecución en Linux (Bash) - RECOMENDADO

El script \desplegarLinux.sh\ es **completamente autónomo**. Detecta permisos faltantes y configura el entorno.

1.  **Dar permisos de ejecución** (solo la primera vez):
   
    chmod +x desplegarLinux.sh
   
2.  **Lanzar el script como usuario normal**:
   
    ./desplegarLinux.sh
   

> [!CAUTION]
> **NO uses sudo**: Ejecutar el script con sudo puede corromper la configuración de Minikube. El script ajustará los permisos de la carpeta y del grupo Docker automáticamente si es necesario.

---

## 🪟 Ejecución en Windows (PowerShell)

1.  Inicia **PowerShell como Administrador**.
2.  Navega hasta la carpeta del proyecto y ejecuta:
    powershell
    .\desplegarWindows.ps1
    

---

## 🔄 Descripción del Flujo Automatizado

1.  **Validación de Permisos:** Comprueba accesos y restaura propiedades de archivos (Linux).
2.  **Limpieza de Recursos:** Elimina despliegues previos y libera caché de imágenes en Minikube/Docker.
3.  **Construcción de Imágenes:** Compila Java y Python (IA) directamente en los contenedores.
4.  **Carga Local a Minikube:** Transfiere imágenes sin necesidad de subirlas a la nube.
5.  **Despliegue K8s:** Aplica el archivo \proyecto.yaml\.
6.  **Configuración de Frontend:** Inyecta la URL dinámica en \web/script.js\ y abre el navegador.

---

## ⚠️ Resolución de Problemas

* **Error Exit Code 132 (Python/IA):** Ocurre si ejecutas Minikube dentro de una Máquina Virtual (ej. VirtualBox) que oculta las instrucciones AVX de la CPU a TensorFlow. Ejecuta el clúster en una máquina física (Bare Metal) o habilita el "Passthrough" de CPU en el hipervisor.
* **Error de Docker (Permission Denied):** Si el script te añade al grupo Docker por primera vez, deja que se reinicie solo.
* **Túnel no genera URL:** Verifica el estado de los pods con \kubectl get pods\.
