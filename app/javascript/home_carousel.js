// Carrossel com looping infinito
function initCarousel() {
  const carousel = document.getElementById('carousel-container');
  if (!carousel) {
    console.log('Carrossel não encontrado no DOM');
    return;
  }

  console.log('Inicializando carrossel...');

  const totalSlides = 4; // Total de slides no DOM (3 reais + 1 cópia)
  let currentSlide = 0;
  const realSlides = 3; // Número de slides únicos
  let carouselInterval = null;

  function moveCarousel() {
    currentSlide++;

    // Cada slide ocupa 25% da largura total (100% / 4)
    const offset = currentSlide * 25;
    carousel.style.transform = `translateX(-${offset}%)`;

    console.log(`Movendo para slide ${currentSlide}, offset: ${offset}%`);

    // Quando chegar no último slide (a cópia do primeiro)
    if (currentSlide === realSlides) {
      setTimeout(() => {
        // Remove a transição para voltar instantaneamente ao início
        carousel.style.transition = 'none';
        carousel.style.transform = 'translateX(0)';
        currentSlide = 0;

        console.log('Resetando para o início');

        // Reativa a transição após um pequeno delay
        setTimeout(() => {
          carousel.style.transition = 'transform 0.8s ease-in-out';
        }, 50);
      }, 800); // Aguarda a transição terminar
    }
  }

  // Limpa qualquer intervalo anterior
  if (carouselInterval) {
    clearInterval(carouselInterval);
  }

  // Inicia o carrossel
  carouselInterval = setInterval(moveCarousel, 4000);
  console.log('Carrossel iniciado com intervalo de 4000ms');
}

// Inicializa quando o DOM estiver pronto
document.addEventListener('DOMContentLoaded', initCarousel);

// Reinicializa quando o Turbo carregar uma nova página
document.addEventListener('turbo:load', initCarousel);

