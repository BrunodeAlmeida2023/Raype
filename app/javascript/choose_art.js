function initChooseArt() {
  const artQuantitySelect = document.getElementById('art_quantity');
  const uploadContainer = document.getElementById('upload-fields-container');
  const previewContainer = document.getElementById('outdoor-preview-container');
  const triedoDisplay = document.getElementById('triedo-display');
  const savedArtData = document.getElementById('saved-art-data');

  if (!artQuantitySelect || !uploadContainer) return;

  let uploadedImages = [];
  let currentImageIndex = 0;
  let rotationInterval = null;

  // Carrega dados das artes já salvas
  let savedArts = [];
  let savedQuantity = 0;
  if (savedArtData) {
    savedQuantity = parseInt(savedArtData.dataset.artQuantity) || 0;
    try {
      savedArts = JSON.parse(savedArtData.dataset.savedArts || '[]');
    } catch (e) {
      savedArts = [];
    }
  }

  // Atualiza campos de upload baseado na quantidade selecionada
  artQuantitySelect.addEventListener('change', function() {
    const quantity = parseInt(this.value);
    updateUploadFields(quantity, []);
    resetPreview();
  });

  function updateUploadFields(quantity, existingArts = []) {
    uploadContainer.innerHTML = '';
    uploadedImages = [];

    if (quantity === 0) {
      uploadContainer.innerHTML = `
        <div class="no-art-message">
          <p>Não se preocupe! Nossa equipe criará uma arte incrível para você.</p>
        </div>
      `;
      if (previewContainer) previewContainer.style.display = 'none';
      return;
    }

    if (previewContainer) previewContainer.style.display = 'block';

    for (let i = 1; i <= quantity; i++) {
      const existingArt = existingArts[i - 1];
      const hasExistingArt = existingArt && existingArt.length > 0;

      const fieldHtml = `
        <div class="home-form-group upload-field">
          <label for="art_file_${i}" class="home-form-label">Arte ${i}:</label>
          <input type="file" 
                 name="art_files[]" 
                 id="art_file_${i}" 
                 accept="image/*" 
                 class="home-form-file-input"
                 data-index="${i}"
                 ${hasExistingArt ? '' : 'required'}>
          <div class="upload-preview" id="preview_${i}">
            ${hasExistingArt 
              ? `<img src="${existingArt}" alt="Arte ${i} salva" class="upload-thumb">
                 <p class="saved-art-label">Arte atual salva</p>` 
              : '<span class="upload-placeholder">Clique para selecionar uma imagem</span>'}
          </div>
          ${hasExistingArt ? '<p class="art-hint">* Selecione um novo arquivo apenas se quiser trocar a arte</p>' : ''}
        </div>
      `;
      uploadContainer.insertAdjacentHTML('beforeend', fieldHtml);

      // Se tem arte salva, adiciona ao array de imagens para preview
      if (hasExistingArt) {
        uploadedImages[i - 1] = existingArt;
      }
    }

    // Adiciona listeners aos novos campos
    document.querySelectorAll('input[name="art_files[]"]').forEach(input => {
      input.addEventListener('change', handleFileSelect);
    });

    // Atualiza o preview com as artes existentes
    if (existingArts.length > 0) {
      updateTriedoPreview();
    }
  }

  function handleFileSelect(event) {
    const file = event.target.files[0];
    const index = parseInt(event.target.dataset.index);
    const previewDiv = document.getElementById(`preview_${index}`);

    if (file) {
      const reader = new FileReader();
      reader.onload = function(e) {
        previewDiv.innerHTML = `<img src="${e.target.result}" alt="Preview ${index}" class="upload-thumb">
                               <p class="saved-art-label" style="color: #28a745;">Nova arte selecionada</p>`;
        uploadedImages[index - 1] = e.target.result;
        updateTriedoPreview();
      };
      reader.readAsDataURL(file);
    }
  }

  function updateTriedoPreview() {
    const validImages = uploadedImages.filter(img => img);

    if (!triedoDisplay) return;

    if (validImages.length === 0) {
      triedoDisplay.innerHTML = `
        <div class="triedo-placeholder">
          <p>Faça upload das suas artes para visualizar</p>
        </div>
      `;
      stopRotation();
      return;
    }

    // Renderiza a primeira imagem
    currentImageIndex = 0;
    renderTriedoImage(validImages[currentImageIndex]);

    // Se tiver mais de uma imagem, inicia a rotação
    if (validImages.length > 1) {
      startRotation(validImages);
    } else {
      stopRotation();
    }
  }

  function renderTriedoImage(imageSrc) {
    if (!triedoDisplay) return;
    triedoDisplay.innerHTML = `
      <div class="triedo-frame">
        <div class="triedo-panel triedo-panel-active">
          <img src="${imageSrc}" alt="Outdoor Preview">
        </div>
      </div>
    `;
  }

  function startRotation(images) {
    stopRotation();

    rotationInterval = setInterval(() => {
      currentImageIndex = (currentImageIndex + 1) % images.length;

      const panel = triedoDisplay.querySelector('.triedo-panel');
      if (panel) {
        panel.classList.add('triedo-rotating');

        setTimeout(() => {
          const img = panel.querySelector('img');
          if (img) img.src = images[currentImageIndex];
          panel.classList.remove('triedo-rotating');
        }, 300);
      }
    }, 3000);
  }

  function stopRotation() {
    if (rotationInterval) {
      clearInterval(rotationInterval);
      rotationInterval = null;
    }
  }

  function resetPreview() {
    uploadedImages = [];
    currentImageIndex = 0;
    stopRotation();
    if (triedoDisplay) {
      triedoDisplay.innerHTML = `
        <div class="triedo-placeholder">
          <p>Faça upload das suas artes para visualizar</p>
        </div>
      `;
    }
  }

  // Inicializa com o valor atual do select e artes salvas
  const initialQuantity = parseInt(artQuantitySelect.value) || 0;

  // Se há artes salvas, carrega-as
  if (savedArts.length > 0 && savedQuantity > 0) {
    updateUploadFields(savedQuantity, savedArts);
  } else {
    updateUploadFields(initialQuantity, []);
  }
}

// Suporte para Turbo (Rails 7) e carregamento normal
document.addEventListener('DOMContentLoaded', initChooseArt);
document.addEventListener('turbo:load', initChooseArt);
document.addEventListener('turbo:render', initChooseArt);

