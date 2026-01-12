// Auto-hide flash messages after 5 seconds
document.addEventListener('DOMContentLoaded', function() {
  const flashMessages = document.querySelectorAll('.flash-notice, .flash-alert');

  flashMessages.forEach(function(message) {
    // Remove the message after 5 seconds
    setTimeout(function() {
      message.style.transition = 'opacity 0.5s ease-out, transform 0.5s ease-out';
      message.style.opacity = '0';
      message.style.transform = 'translateX(-50%) translateY(-30px)';

      // Remove from DOM after animation
      setTimeout(function() {
        message.remove();
      }, 500);
    }, 5000);

    // Add click to close functionality
    message.style.cursor = 'pointer';
    message.addEventListener('click', function() {
      message.style.transition = 'opacity 0.3s ease-out';
      message.style.opacity = '0';
      setTimeout(function() {
        message.remove();
      }, 300);
    });
  });
});

