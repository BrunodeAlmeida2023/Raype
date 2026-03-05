// Password Toggle Functionality
function initPasswordToggle() {
  // Remove event listeners antigos para evitar duplicação
  const passwordToggles = document.querySelectorAll('.auth-password-toggle');

  passwordToggles.forEach(toggle => {
    // Remove a flag de inicializado se existir
    if (toggle.dataset.initialized === 'true') {
      return; // Já foi inicializado, não duplicar
    }

    // Marcar como inicializado
    toggle.dataset.initialized = 'true';

    // Função para alternar a visibilidade da senha
    const togglePassword = function(event) {
      // Prevenir comportamento padrão e propagação do evento
      event.preventDefault();
      event.stopPropagation();

      const wrapper = this.closest('.auth-password-wrapper');
      if (!wrapper) return;

      const passwordField = wrapper.querySelector('.auth-password-field');
      const eyeClosed = this.querySelector('.eye-closed');
      const eyeOpen = this.querySelector('.eye-open');

      if (!passwordField || !eyeClosed || !eyeOpen) return;

      if (passwordField.type === 'password') {
        // Show password
        passwordField.type = 'text';
        eyeClosed.style.display = 'none';
        eyeOpen.style.display = 'block';
        this.setAttribute('aria-label', 'Ocultar senha');
      } else {
        // Hide password
        passwordField.type = 'password';
        eyeClosed.style.display = 'block';
        eyeOpen.style.display = 'none';
        this.setAttribute('aria-label', 'Mostrar senha');
      }
    };

    // Adicionar evento de clique para desktop
    toggle.addEventListener('click', togglePassword);

    // Adicionar evento de toque para mobile (previne duplo disparo)
    toggle.addEventListener('touchend', function(event) {
      togglePassword.call(this, event);
    });

    // Prevenir que o mousedown foque o campo de senha
    toggle.addEventListener('mousedown', function(event) {
      event.preventDefault();
    });

    // Prevenir que o touchstart foque o campo de senha
    toggle.addEventListener('touchstart', function(event) {
      event.preventDefault();
    });
  });
}

// Inicializar em múltiplos eventos para garantir que funcione sempre
document.addEventListener('turbo:load', initPasswordToggle);
document.addEventListener('turbo:render', initPasswordToggle);
document.addEventListener('DOMContentLoaded', initPasswordToggle);

// Também reinicializar após frames do Turbo
document.addEventListener('turbo:frame-load', initPasswordToggle);

