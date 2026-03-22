# Imagen base ligera de Python
FROM python:3.11-slim

# Directorio de trabajo
WORKDIR /app

# Instalamos dependencias del sistema necesarias para procesamiento de imagen
RUN apt-get update && apt-get install -y libgl1 libglib2.0-0 && rm -rf /var/lib/apt/lists/*

# Instalamos las librerías de Python
RUN pip install --no-cache-dir fastapi uvicorn tensorflow pillow numpy python-multipart

# Copiamos el código y el modelo
COPY main.py .
COPY animal_image_classifier.keras . 

# Exponemos el puerto de FastAPI
EXPOSE 8000

# Arrancamos el servidor
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]