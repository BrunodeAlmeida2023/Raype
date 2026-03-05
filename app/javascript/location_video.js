// Gerencia a exibição de vídeos por localização de outdoor
document.addEventListener("turbo:load", function() {
  initLocationVideo();
});

document.addEventListener("DOMContentLoaded", function() {
  initLocationVideo();
});

function initLocationVideo() {
  const locationSelect = document.getElementById("outdoor_location_select");
  const videoContainer = document.getElementById("location-video-container");
  const videoIframe = document.getElementById("location-video-iframe");

  console.log("🎥 Iniciando location_video.js");
  console.log("Select encontrado:", !!locationSelect);
  console.log("Container encontrado:", !!videoContainer);
  console.log("Iframe encontrado:", !!videoIframe);

  if (!locationSelect || !videoContainer || !videoIframe) {
    console.log("❌ Elementos não encontrados, abortando");
    return;
  }

  // Parse o mapeamento de vídeos do data attribute
  let locationVideos = {};
  try {
    const videosData = videoContainer.getAttribute("data-videos");
    console.log("📹 Data-videos raw:", videosData);
    if (videosData) {
      locationVideos = JSON.parse(videosData);
      console.log("📹 Mapeamento de vídeos:", locationVideos);
    }
  } catch (error) {
    console.error("❌ Erro ao parsear mapeamento de vídeos:", error);
    return;
  }

  function updateVideoDisplay() {
    const selectedLocation = locationSelect.value;
    console.log("🎯 Localização selecionada:", selectedLocation);
    console.log("🎯 Vídeo disponível para essa localização:", locationVideos[selectedLocation]);

    // Verifica se a localização selecionada tem vídeo
    if (selectedLocation && locationVideos[selectedLocation]) {
      console.log("✅ Mostrando vídeo");
      // Atualiza o src do iframe
      videoIframe.src = locationVideos[selectedLocation];

      // Exibe o container com animação suave
      videoContainer.style.display = "block";

      // Força reflow para animação
      setTimeout(() => {
        videoContainer.style.opacity = "1";
      }, 10);
    } else {
      console.log("❌ Ocultando vídeo");
      // Oculta o container
      videoContainer.style.opacity = "0";

      // Aguarda a animação antes de esconder
      setTimeout(() => {
        videoContainer.style.display = "none";
        videoIframe.src = ""; // Limpa o vídeo para parar reprodução
      }, 300);
    }
  }

  // Verificar estado inicial (caso já tenha algo selecionado)
  updateVideoDisplay();

  // Ouvir mudanças no select
  locationSelect.addEventListener("change", updateVideoDisplay);
}


