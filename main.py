import logging
import io
import numpy as np
import tensorflow as tf
from fastapi import FastAPI, UploadFile, File, HTTPException
from PIL import Image
# IMPORTANTE: Importamos la función de preprocesamiento específica de EfficientNet
from tensorflow.keras.applications.efficientnet import preprocess_input

# 1. Configuración del Logging
logging.basicConfig(
    level=logging.INFO, 
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = FastAPI(title="API de Clasificación de Animales")

# IMPORTANTE: Reemplaza "animal_image_classifier.keras" por el nombre de tu archivo si es diferente
MODEL_PATH = "animal_image_classifier.keras" 

# Lista de 90 animales extraída del notebook
ANIMAL_CLASSES = [
    'antelope', 'badger', 'bat', 'bear', 'bee', 'beetle', 'bison', 'boar', 'butterfly', 'cat',
    'caterpillar', 'chimpanzee', 'cockroach', 'cow', 'coyote', 'crab', 'crow', 'deer', 'dog',
    'dolphin', 'donkey', 'dragonfly', 'duck', 'eagle', 'elephant', 'flamingo', 'fly', 'fox',
    'goat', 'goldfish', 'goose', 'gorilla', 'grasshopper', 'hamster', 'hare', 'hedgehog',
    'hippopotamus', 'hornbill', 'horse', 'hummingbird', 'hyena', 'jellyfish', 'kangaroo',
    'koala', 'ladybugs', 'leopard', 'lion', 'lizard', 'lobster', 'mosquito', 'moth', 'mouse',
    'octopus', 'okapi', 'orangutan', 'otter', 'owl', 'ox', 'oyster', 'panda', 'parrot',
    'pelecaniformes', 'penguin', 'pig', 'pigeon', 'porcupine', 'possum', 'raccoon', 'rat',
    'reindeer', 'rhinoceros', 'sandpiper', 'seahorse', 'seal', 'shark', 'sheep', 'snake',
    'sparrow', 'squid', 'squirrel', 'starfish', 'swan', 'tiger', 'turkey', 'turtle', 'whale',
    'wolf', 'wombat', 'woodpecker', 'zebra'
]

# 2. Carga del Modelo
try:
    model = tf.keras.models.load_model(MODEL_PATH)
    logger.info(f"Modelo '{MODEL_PATH}' cargado exitosamente.")
except Exception as e:
    logger.error(f"Error crítico al cargar el modelo: {e}")
    model = None

def preprocess_image(image_bytes: bytes) -> np.ndarray:
    """Procesa los bytes de la imagen idéntico a como se hizo en el entrenamiento."""
    try:
        # Abrimos la imagen y aseguramos que es RGB
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        # El notebook usa 224x224
        image = image.resize((224, 224)) 
        
        # Convertimos a array de numpy
        img_array = np.array(image, dtype=np.float32)
        
        # Aplicamos el preprocesamiento de EfficientNet
        img_array = preprocess_input(img_array)
        
        # Añadimos la dimensión del batch: (1, 224, 224, 3)
        img_array = np.expand_dims(img_array, axis=0) 
        return img_array
    except Exception as e:
        logger.error(f"Fallo al procesar la imagen: {e}")
        raise ValueError("El archivo proporcionado no es una imagen válida o está corrupto.")

@app.post("/predict")
async def predict_animal(file: UploadFile = File(...)):
    if model is None:
        raise HTTPException(status_code=500, detail="Servicio no disponible: El modelo no cargó.")

    if not file.content_type.startswith("image/"):
        logger.warning(f"Petición rechazada. Tipo MIME no válido: {file.content_type}")
        raise HTTPException(status_code=400, detail="El archivo debe ser una imagen válida.")

    try:
        image_bytes = await file.read()
        img_array = preprocess_image(image_bytes)

        # Inferencia
        predictions = model.predict(img_array)
        predicted_class_idx = np.argmax(predictions[0])
        confidence = float(predictions[0][predicted_class_idx])
        
        predicted_animal = ANIMAL_CLASSES[predicted_class_idx]

        logger.info(f"Predicción: {predicted_animal} (Confianza: {confidence:.2f})")

        return {
            "animal": predicted_animal,
            "confidence": confidence
        }

    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        logger.error(f"Error interno durante la inferencia: {e}")
        raise HTTPException(status_code=500, detail="Error interno al procesar la predicción.")
    
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)