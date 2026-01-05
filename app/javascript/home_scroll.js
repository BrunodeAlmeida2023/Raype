// Scroll suave para contato
document.addEventListener('DOMContentLoaded', function() {
  const contactButton = document.getElementById('contact-button');
  const contactSection = document.getElementById('contact-section');

  if (contactButton && contactSection) {
    contactButton.addEventListener('click', function(e) {
      e.preventDefault();
      contactSection.scrollIntoView({
        behavior: 'smooth',
        block: 'start'
      });
    });
  }
});

