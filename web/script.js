const dropZone = document.getElementById('drop-zone');
const fileInput = document.getElementById('file-input');
const btn = document.getElementById('btn-upload');
const resultsArea = document.getElementById('results-area');
const statusText = document.getElementById('status-text');

// --- PASO CLAVE: Reemplaza con el link de 'minikube service java-service --url' ---
const URL_API = "http://127.0.0.1:63658/api/v1/classify";;;; 

dropAreaOnClick = () => fileInput.click();
dropZone.addEventListener('click', dropAreaOnClick);

fileInput.onchange = () => {
    if (fileInput.files.length > 0) {
        statusText.innerText = `${fileInput.files.length} archivos seleccionados`;
        btn.disabled = false;
    }
};

btn.onclick = async () => {
    btn.disabled = true;
    btn.innerText = "Procesando...";
    resultsArea.innerHTML = ""; 

    const formData = new FormData();
    for (let file of fileInput.files) {
        formData.append("image", file);
    }

    try {
        const response = await fetch(URL_API, { method: 'POST', body: formData });
        const data = await response.json(); 

        data.forEach(itemText => {
            // --- LA CORRECCIÓN ESTÁ AQUÍ ---
            // Convertimos el texto JSON que envía Java en un objeto JS
            const item = JSON.parse(itemText); 
            // -------------------------------

            const card = document.createElement('div');
            
            if (item.error) {
                card.className = 'card error';
                card.innerHTML = `<span class="filename">${item.archivo || 'Archivo'}</span> 
                                  <span class="prediction">${item.error}</span>`;
            } else {
                card.className = 'card';
                // Aseguramos que confidence sea un número
                const rawConf = parseFloat(item.confidence);
                const p = isNaN(rawConf) ? "0.00" : (rawConf * 100).toFixed(2);
                
                card.innerHTML = `<span class="filename">${item.archivo || 'Imagen'}</span> 
                                  <span class="prediction">${item.animal} (${p}%)</span>`;
            }
            resultsArea.appendChild(card);
        });

    } catch (error) {
        alert("Error de conexión: ¿Está abierto el túnel de Minikube?");
        console.error(error);
    } finally {
        btn.disabled = false;
        btn.innerText = "Enviar al Clúster";
    }
};
