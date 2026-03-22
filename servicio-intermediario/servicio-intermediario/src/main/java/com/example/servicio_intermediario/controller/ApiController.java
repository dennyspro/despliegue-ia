package com.example.servicio_intermediario.controller;

import com.example.servicio_intermediario.service.PredictionService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/api/v1")
@CrossOrigin(origins = "*", allowedHeaders = "*", methods = {RequestMethod.POST, RequestMethod.GET, RequestMethod.OPTIONS})public class ApiController {

    private static final Logger logger = LoggerFactory.getLogger(ApiController.class);
    private final PredictionService predictionService;

    public ApiController(PredictionService predictionService) {
        this.predictionService = predictionService;
    }

    @PostMapping("/classify")
    public ResponseEntity<?> classifyAnimal(@RequestParam("image") MultipartFile[] images) { // 2. Mejora: Recibe array
        logger.info("Petición recibida en el endpoint /classify para {} archivos", images.length);

        List<String> resultados = new ArrayList<>();

        for (MultipartFile image : images) {
            // 3. Mejora: Validación de que sea imagen
            if (image.isEmpty() || image.getContentType() == null || !image.getContentType().startsWith("image/")) {
                logger.warn("Archivo rechazado por no ser imagen: {}", image.getOriginalFilename());
                resultados.add("{\"archivo\": \"" + image.getOriginalFilename() + "\", \"error\": \"No es una imagen válida.\"}");
                continue;
            }

            try {
                // Llamada a tu servicio original
                String result = predictionService.getPredictionFromPython(image);
                // Insertamos el nombre del archivo en el JSON de respuesta para identificarlo en la web
                resultados.add(result.replaceFirst("\\{", "{\"archivo\":\"" + image.getOriginalFilename() + "\","));

            } catch (RuntimeException e) {
                logger.error("Error procesando {}: {}", image.getOriginalFilename(), e.getMessage());
                resultados.add("{\"archivo\": \"" + image.getOriginalFilename() + "\", \"error\": \"" + e.getMessage() + "\"}");
            }
        }

        return ResponseEntity.ok(resultados);
    }
}