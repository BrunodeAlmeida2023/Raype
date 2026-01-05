// Máscaras de CPF e CNPJ
document.addEventListener('turbo:load', initDocumentMask);
document.addEventListener('DOMContentLoaded', initDocumentMask);

function initDocumentMask() {
  const tipoSelect = document.getElementById('documento_tipo_select');
  const numeroInput = document.getElementById('documento_numero_input');

  if (!tipoSelect || !numeroInput) return;

  function updatePlaceholder() {
    if (tipoSelect.value === 'cpf') {
      numeroInput.placeholder = '000.000.000-00';
      numeroInput.maxLength = 14; // CPF: 11 dígitos + 3 caracteres de formatação
    } else {
      numeroInput.placeholder = '00.000.000/0000-00';
      numeroInput.maxLength = 18; // CNPJ: 14 dígitos + 4 caracteres de formatação
    }
    numeroInput.value = '';
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

  tipoSelect.addEventListener('change', updatePlaceholder);

  numeroInput.addEventListener('input', function() {
    if (tipoSelect.value === 'cpf') {
      this.value = formatCPF(this.value);
    } else {
      this.value = formatCNPJ(this.value);
    }
  });

  // Definir placeholder inicial
  updatePlaceholder();
}

