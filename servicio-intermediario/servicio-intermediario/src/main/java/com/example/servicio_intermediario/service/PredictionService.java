package com.example.servicio_intermediario.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

@Service
public class PredictionService {

    private static final Logger logger = LoggerFactory.getLogger(PredictionService.class);
    // URL por defecto del servicio FastAPI que creamos en el Paso 2
    private final String pythonApiUrl = "http://ai-service:8000/predict"; 
    private final RestTemplate restTemplate = new RestTemplate();

    public String getPredictionFromPython(MultipartFile file) {
        try {
            logger.info("Iniciando comunicación con el servicio de IA en Python...");

            // Preparamos el archivo para enviarlo como multipart/form-data
            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            body.add("file", new ByteArrayResource(file.getBytes()) {
                @Override
                public String getFilename() {
                    return file.getOriginalFilename();
                }
            });

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);

            HttpEntity<MultiValueMap<String, Object>> requestEntity = new HttpEntity<>(body, headers);

            // Llamada POST al servicio de Python
            ResponseEntity<String> response = restTemplate.postForEntity(pythonApiUrl, requestEntity, String.class);

            logger.info("Respuesta recibida del servicio de IA correctamente.");
            return response.getBody();

        } catch (Exception e) {
            logger.error("Error al comunicarse con el servicio de IA: {}", e.getMessage());
            throw new RuntimeException("El servicio de predicción no está disponible en este momento.");
        }
    }
}