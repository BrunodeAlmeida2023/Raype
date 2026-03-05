// Máscaras de CPF e CNPJ
function initDocumentMask() {
  const tipoSelect = document.getElementById('documento_tipo_select');
  const numeroInput = document.getElementById('documento_numero_input');

  if (!tipoSelect || !numeroInput) return;

  // Verificar se já foi inicializado para evitar duplicação
  if (numeroInput.dataset.initialized === 'true') {
    return;
  }

  // Marcar como inicializado
  numeroInput.dataset.initialized = 'true';
  tipoSelect.dataset.initialized = 'true';

  function updatePlaceholder() {
    if (tipoSelect.value === 'cpf') {
      numeroInput.placeholder = '000.000.000-00';
      numeroInput.maxLength = 14; // CPF: 11 dígitos + 3 caracteres de formatação
    } else {
      numeroInput.placeholder = '00.000.000/0000-00';
      numeroInput.maxLength = 18; // CNPJ: 14 dígitos + 4 caracteres de formatação
    }
    // Não limpar o valor quando atualizar o placeholder (para manter após erros)
    // numeroInput.value = '';
  }

  function formatCPF(value) {
    // Remove tudo que não é dígito
    value = value.replace(/\D/g, '');

    // Limita a 11 dígitos
    if (value.length > 11) value = value.slice(0, 11);

    // Aplica a máscara: 000.000.000-00
    value = value.replace(/(\d{3})(\d)/, '$1.$2');
    value = value.replace(/(\d{3})(\d)/, '$1.$2');
    value = value.replace(/(\d{3})(\d{1,2})$/, '$1-$2');

    return value;
  }

  function formatCNPJ(value) {
    // Remove tudo que não é dígito
    value = value.replace(/\D/g, '');

    // Limita a 14 dígitos
    if (value.length > 14) value = value.slice(0, 14);

    // Aplica a máscara: 00.000.000/0000-00
    value = value.replace(/(\d{2})(\d)/, '$1.$2');
    value = value.replace(/(\d{3})(\d)/, '$1.$2');
    value = value.replace(/(\d{3})(\d)/, '$1/$2');
    value = value.replace(/(\d{4})(\d{1,2})$/, '$1-$2');

    return value;
  }

  // Aplicar máscara no valor inicial (caso venha preenchido após erro)
  function applyInitialMask() {
    if (numeroInput.value) {
      if (tipoSelect.value === 'cpf') {
        numeroInput.value = formatCPF(numeroInput.value);
      } else {
        numeroInput.value = formatCNPJ(numeroInput.value);
      }
    }
  }

  tipoSelect.addEventListener('change', function() {
    updatePlaceholder();
    applyInitialMask();
  });

  numeroInput.addEventListener('input', function() {
    if (tipoSelect.value === 'cpf') {
      this.value = formatCPF(this.value);
    } else {
      this.value = formatCNPJ(this.value);
    }
  });

  // Definir placeholder inicial e aplicar máscara se já houver valor
  updatePlaceholder();
  applyInitialMask();
}

// Inicializar em múltiplos eventos para garantir que funcione sempre
document.addEventListener('turbo:load', initDocumentMask);
document.addEventListener('turbo:render', initDocumentMask);
document.addEventListener('DOMContentLoaded', initDocumentMask);

// Também reinicializar após frames do Turbo
document.addEventListener('turbo:frame-load', initDocumentMask);

