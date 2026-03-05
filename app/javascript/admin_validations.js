// Admin Validations - Validações e confirmações

export function confirmDelete(message = 'Tem certeza que deseja excluir?') {
  return confirm(message);
}

export function confirmAction(message) {
  return confirm(message);
}

export function validateForm(formId) {
  const form = document.getElementById(formId);
  if (!form) return false;

  const requiredFields = form.querySelectorAll('[required]');
  let isValid = true;

  requiredFields.forEach(field => {
    if (!field.value || field.value.trim() === '') {
      isValid = false;
      field.classList.add('error');
    } else {
      field.classList.remove('error');
    }
  });

  return isValid;
}

// Adiciona classe de erro em campos inválidos
export function highlightErrors(form) {
  const invalidFields = form.querySelectorAll(':invalid');
  invalidFields.forEach(field => {
    field.classList.add('error');
  });
}

// Remove classe de erro quando usuário começa a digitar
export function setupErrorRemoval() {
  document.querySelectorAll('input[required], select[required], textarea[required]').forEach(field => {
    field.addEventListener('input', function() {
      this.classList.remove('error');
    });
  });
}

// Inicialização
document.addEventListener('DOMContentLoaded', setupErrorRemoval);
document.addEventListener('turbo:load', setupErrorRemoval);

