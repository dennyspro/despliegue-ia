# =========================================================================
# SCRIPT DE DESPLIEGUE - RUTAS RELATIVAS (PORTABLE)
# =========================================================================

# 1. Definimos la base relativa al sitio donde esta el script
$BASE = $PSScriptRoot

# Rutas calculadas desde la posicion del script
$PATH_JAVA   = Join-Path $BASE "servicio-intermediario\servicio-intermediario"
$PATH_PYTHON = $BASE # Segun me dijiste, la IA esta en la misma carpeta raiz
$YAML_PATH   = Join-Path $PATH_JAVA "proyecto.yaml"
$JS_PATH     = Join-Path $BASE "web\script.js"

# LIMPIEZA PROFUNDA (BORRA IMÁGENES Y RECURSOS)

Write-Host "--- 1. LIMPIEZA TOTAL ---" -ForegroundColor Magenta

Write-Host "--- 1. Eliminando recursos de Kubernetes ---" -ForegroundColor Yellow
kubectl delete -f $YAML_PATH --ignore-not-found

Write-Host "--- 2. Eliminando imagenes del cache de Minikube ---" -ForegroundColor Cyan
minikube image rm java-service:latest
minikube image rm ai-service:latest

Write-Host "--- 3. Eliminando imagenes locales de Docker ---" -ForegroundColor Cyan
docker rmi java-service:latest ai-service:latest -f

if (Test-Path $YAML_PATH) {
    kubectl delete -f $YAML_PATH --ignore-not-found
}

Write-Host "--- 2. COMPILANDO JAVA  ---" -ForegroundColor Magenta
if (Test-Path "$PATH_JAVA\mvnw.cmd") {
    Set-Location $PATH_JAVA
    .\mvnw.cmd clean package -DskipTests
    docker build -t java-service:latest .
} else {
    Write-Error "No se encontro mvnw.cmd en $PATH_JAVA"
    return
}

Write-Host "--- 3. CONSTRUYENDO PYTHON ---" -ForegroundColor Magenta
Set-Location $PATH_PYTHON
if (Test-Path "Dockerfile") {
    docker build -t ai-service:latest .
} else {
    Write-Warning "No se encontro Dockerfile en $PATH_PYTHON. Revisa si el codigo de la IA esta aqui."
}

Write-Host "--- 4. CARGA LOCAL A MINIKUBE ---" -ForegroundColor Magenta
minikube image load java-service:latest --overwrite
if (docker images -q ai-service:latest) {
    minikube image load ai-service:latest --overwrite
}

Write-Host "--- 5. DESPLEGANDO EN KUBERNETES ---" -ForegroundColor Magenta
kubectl apply -f $YAML_PATH

Write-Host "--- 6. GENERANDO TUNEL Y WEB ---" -ForegroundColor Magenta
Start-Sleep -Seconds 15
$URL = (minikube service java-service --url | Select-Object -First 1).Trim()

if ($URL -like "http*") {
    # Actualizar JS con ruta relativa
    (Get-Content $JS_PATH) -replace 'const URL_API = ".*"', "const URL_API = `"$URL/api/v1/classify`";" | Set-Content $JS_PATH
    
    Write-Host "--- TODO LISTO. URL: $URL ---" -ForegroundColor Magenta
    # Abrir el HTML usando la ruta relativa calculada
    $INDEX_HTML = Join-Path $BASE "web\index.html"
    Start-Process "chrome.exe" $INDEX_HTML
}

# Volvemos a la carpeta original al terminar
Set-Location $BASE