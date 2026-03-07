function initChooseArt() {
  const hasOwnArtSelect = document.getElementById('has_own_art');
  const facesSelectionGroup = document.getElementById('faces-selection-group');
  const uploadContainer = document.getElementById('upload-fields-container');
  const noArtMessage = document.getElementById('no-art-message');
  const previewContainer = document.getElementById('outdoor-preview-container');
  const triedoDisplay = document.getElementById('triedo-display');
  const facesCountHint = document.getElementById('faces-count-hint');
  const form = document.getElementById('choose-art-form');
  const dataContainer = document.getElementById('choose-art-data');

  if (!hasOwnArtSelect || !facesSelectionGroup) return;

  // Proteção contra duplicação
  if (hasOwnArtSelect.dataset.initialized === 'true') return;
  hasOwnArtSelect.dataset.initialized = 'true';

  let uploadedImages = [];
  let currentImageIndex = 0;
  let rotationInterval = null;
  let selectedFaces = [];

  // Carrega dados salvos
  if (dataContainer) {
    try {
      const hasOwnArtValue = dataContainer.dataset.hasOwnArt;
      const hasOwnArt = hasOwnArtValue === 'true';
      selectedFaces = JSON.parse(dataContainer.dataset.selectedFaces || '[]');
      const savedArts = JSON.parse(dataContainer.dataset.savedArts || '[]');

      console.log('🔄 Carregando dados salvos:', {
        hasOwnArtValue,
        hasOwnArt,
        selectedFaces,
        savedArts
      });

      // Se já tem valor de hasOwnArt definido, restaura
      if (hasOwnArtValue && hasOwnArtValue !== '') {
        hasOwnArtSelect.value = hasOwnArtValue;
        showFacesSelection();

        // Restaura checkboxes selecionados
        if (selectedFaces.length > 0) {
          selectedFaces.forEach(faceNum => {
            const checkbox = document.getElementById(`face_${faceNum}`);
            if (checkbox) {
              checkbox.checked = true;
            }
          });
          updateFacesDisplay();

          // Mostra conteúdo apropriado
          if (hasOwnArt) {
            // Se tem arte própria, prepara arrays de imagens
            if (savedArts.length > 0) {
              // Preenche uploadedImages no índice correto para cada face
              uploadedImages = [];
              selectedFaces.forEach((faceNum, index) => {
                if (savedArts[index]) {
                  uploadedImages[index] = savedArts[index];
                }
              });
              console.log('📷 Imagens carregadas:', uploadedImages);
            }

            showUploadFields();
            updateUploadFields();

            // Mostra preview se tem imagens
            if (savedArts.length > 0) {
              setTimeout(() => {
                updateTriedoPreview();
              }, 100);
            }
          } else {
            // Não tem arte própria
            showNoArtMessage();
          }
        }
      }
    } catch (e) {
      console.error('❌ Erro ao carregar dados:', e);
    }
  }

  // Listener para seleção de arte própria
  hasOwnArtSelect.addEventListener('change', function() {
    const value = this.value;

    if (value === '') {
      hideFacesSelection();
      return;
    }

    showFacesSelection();
    resetFaces();
  });

  // Listeners para checkboxes de faces
  const faceCheckboxes = document.querySelectorAll('.face-checkbox');
  faceCheckboxes.forEach(checkbox => {
    // Suporte para click e touch
    const handler = function() {
      // Pequeno delay para garantir que o estado do checkbox foi atualizado
      setTimeout(() => {
        updateSelectedFaces();
        updateFacesDisplay();

        const hasOwnArt = hasOwnArtSelect.value === 'true';
        if (selectedFaces.length > 0) {
          if (hasOwnArt) {
            showUploadFields();
            updateUploadFields();
          } else {
            showNoArtMessage();
          }
        } else {
          hideAllContent();
        }
      }, 50);
    };

    checkbox.addEventListener('change', handler);

    // 📱 Suporte adicional para mobile
    const label = checkbox.closest('.face-checkbox-label');
    if (label) {
      label.addEventListener('touchend', function(e) {
        // Previne comportamento duplicado no mobile
        if (e.cancelable) {
          e.preventDefault();
        }
        checkbox.checked = !checkbox.checked;
        handler();
      });
    }
  });

  function showFacesSelection() {
    facesSelectionGroup.style.display = 'block';
  }

  function hideFacesSelection() {
    facesSelectionGroup.style.display = 'none';
    hideAllContent();
    resetFaces();
  }

  function resetFaces() {
    const checkboxes = document.querySelectorAll('.face-checkbox');
    checkboxes.forEach(cb => cb.checked = false);
    selectedFaces = [];
    updateFacesDisplay();
    hideAllContent();
  }

  function updateSelectedFaces() {
    const checkboxes = document.querySelectorAll('.face-checkbox:checked');
    selectedFaces = Array.from(checkboxes).map(cb => parseInt(cb.value));
  }

  function updateFacesDisplay() {
    if (!facesCountHint) return;

    if (selectedFaces.length === 0) {
      facesCountHint.textContent = 'Selecione pelo menos uma face';
      facesCountHint.style.color = '#dc3545';
      facesCountHint.style.borderColor = '#dc3545';
    } else {
      const facesText = selectedFaces.length === 1 ? 'face' : 'faces';
      const artsText = selectedFaces.length === 1 ? 'arte' : 'artes';
      facesCountHint.textContent = `${selectedFaces.length} ${facesText} selecionada(s) = ${selectedFaces.length} ${artsText}`;
      facesCountHint.style.color = '#ff6b00';
      facesCountHint.style.borderColor = '#ff6b00';
    }
  }

  function showUploadFields() {
    if (uploadContainer) uploadContainer.style.display = 'grid';
    if (noArtMessage) noArtMessage.style.display = 'none';
    if (previewContainer) previewContainer.style.display = 'block';
  }

  function showNoArtMessage() {
    if (uploadContainer) uploadContainer.style.display = 'none';
    if (noArtMessage) noArtMessage.style.display = 'block';
    if (previewContainer) previewContainer.style.display = 'none';
  }

  function hideAllContent() {
    if (uploadContainer) uploadContainer.style.display = 'none';
    if (noArtMessage) noArtMessage.style.display = 'none';
    if (previewContainer) previewContainer.style.display = 'none';
    uploadedImages = [];
    resetPreview();
  }

  function updateUploadFields() {
    if (!uploadContainer) return;

    uploadContainer.innerHTML = '';

    const facesCount = selectedFaces.length;
    if (facesCount === 0) return;

    for (let i = 0; i < facesCount; i++) {
      const faceNumber = selectedFaces[i];
      const hasExistingArt = uploadedImages[i] && uploadedImages[i].length > 0;

      const fieldHtml = `
        <div class="home-form-group upload-field">
          <label for="art_file_${faceNumber}" class="home-form-label">Arte para Face ${faceNumber}:</label>
          <input type="file" 
                 name="art_files[]" 
                 id="art_file_${faceNumber}" 
                 class="home-form-input file-input" 
                 accept="image/*"
                 data-face="${faceNumber}"
                 ${hasExistingArt ? '' : 'required'}>
          ${hasExistingArt ? '<p class="file-hint">✓ Arte já carregada anteriormente</p>' : ''}
        </div>
      `;
      uploadContainer.insertAdjacentHTML('beforeend', fieldHtml);
    }

    // Adiciona listeners aos novos inputs
    const fileInputs = uploadContainer.querySelectorAll('.file-input');
    fileInputs.forEach(input => {
      input.addEventListener('change', handleFileSelect);
    });
  }

  function handleFileSelect(event) {
    const file = event.target.files[0];
    if (!file) return;

    // 🚀 OTIMIZAÇÃO: Limita tamanho do arquivo para melhor performance
    const maxSize = 5 * 1024 * 1024; // 5MB
    if (file.size > maxSize) {
      alert('⚠️ Arquivo muito grande! Por favor, selecione uma imagem menor que 5MB.');
      event.target.value = '';
      return;
    }

    // Mostra feedback visual
    const fieldGroup = event.target.closest('.upload-field');
    if (fieldGroup) {
      const hint = fieldGroup.querySelector('.file-hint');
      if (hint) {
        hint.textContent = '⏳ Processando...';
        hint.style.color = '#ff6b00';
      }
    }

    const reader = new FileReader();
    reader.onload = function(e) {
      const faceNumber = parseInt(event.target.dataset.face);
      const faceIndex = selectedFaces.indexOf(faceNumber);

      if (faceIndex !== -1) {
        uploadedImages[faceIndex] = e.target.result;

        // Atualiza feedback
        if (fieldGroup) {
          const hint = fieldGroup.querySelector('.file-hint');
          if (hint) {
            hint.textContent = '✓ Arquivo selecionado';
            hint.style.color = '#28a745';
          }
        }

        // 🚀 OTIMIZAÇÃO: Usa requestAnimationFrame para não bloquear UI
        requestAnimationFrame(() => {
          updateTriedoPreview();
        });
      }
    };

    reader.onerror = function() {
      alert('❌ Erro ao ler o arquivo. Tente novamente.');
      event.target.value = '';
    };

    reader.readAsDataURL(file);
  }

  function updateTriedoPreview() {
    if (!triedoDisplay) return;

    const validImages = uploadedImages.filter(img => img && img.length > 0);

    if (validImages.length === 0) {
      resetPreview();
      return;
    }

    if (validImages.length === 1) {
      renderTriedoImage(validImages[0]);
    } else {
      renderTriedoImage(validImages[0]);
      startRotation(validImages);
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

  // Validação do formulário
  if (form) {
    let isSubmitting = false;

    form.addEventListener('submit', function(e) {
      // Previne múltiplos submits
      if (isSubmitting) {
        e.preventDefault();
        return false;
      }

      const hasOwnArtValue = hasOwnArtSelect.value;

      if (hasOwnArtValue === '') {
        e.preventDefault();
        alert('Por favor, selecione se você tem artes prontas ou não.');
        hasOwnArtSelect.focus();
        hasOwnArtSelect.scrollIntoView({ behavior: 'smooth', block: 'center' });
        return false;
      }

      const checkedFaces = document.querySelectorAll('.face-checkbox:checked');
      if (checkedFaces.length === 0) {
        e.preventDefault();
        alert('Por favor, selecione pelo menos uma face do outdoor.');
        if (facesSelectionGroup) {
          facesSelectionGroup.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
        return false;
      }

      // Se tem arte própria, verifica se os arquivos foram selecionados
      if (hasOwnArtValue === 'true') {
        if (!uploadContainer) {
          e.preventDefault();
          alert('Erro ao processar formulário. Recarregue a página.');
          return false;
        }

        const fileInputs = uploadContainer.querySelectorAll('.file-input[required]');
        let allFilled = true;

        fileInputs.forEach(input => {
          if (!input.files || input.files.length === 0) {
            allFilled = false;
          }
        });

        if (!allFilled) {
          e.preventDefault();
          alert('Por favor, faça upload das artes para todas as faces selecionadas.');
          return false;
        }
      }

      // Tudo válido - mostra loading
      isSubmitting = true;
      const submitBtn = form.querySelector('#submit-choose-art');
      if (submitBtn) {
        submitBtn.disabled = true;
        submitBtn.textContent = '⏳ Processando...';
        submitBtn.style.opacity = '0.7';
        submitBtn.style.cursor = 'not-allowed';
      }

      // Se não tem arte própria, pode enviar normalmente
      return true;
    });
  }
}

// Inicialização
document.addEventListener('DOMContentLoaded', initChooseArt);
document.addEventListener('turbo:load', initChooseArt);
document.addEventListener('turbo:render', initChooseArt);







