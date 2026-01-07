// Password Toggle Functionality
document.addEventListener('turbo:load', function() {
  const passwordToggles = document.querySelectorAll('.auth-password-toggle');

  passwordToggles.forEach(toggle => {
    toggle.addEventListener('click', function() {
      const wrapper = this.closest('.auth-password-wrapper');
      const passwordField = wrapper.querySelector('.auth-password-field');
      const eyeClosed = this.querySelector('.eye-closed');
      const eyeOpen = this.querySelector('.eye-open');

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
    });
  });
});

