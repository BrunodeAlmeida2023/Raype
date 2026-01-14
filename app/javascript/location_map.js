document.addEventListener("turbo:load", function() {
  initLocationMap();
});

document.addEventListener("DOMContentLoaded", function() {
  initLocationMap();
});

function initLocationMap() {
  const locationSelect = document.getElementById("outdoor_location_select");
  const mapBtn = document.getElementById("location-map-btn");

  if (!locationSelect || !mapBtn) return;

  // Mapeamento de localizações para links do Google Maps
  const locationLinks = {
    "outdoor_02": "https://www.google.com/maps/place/Dois+Vizinhos,+PR,+85660-000/@-25.7501245,-53.0667007,14z/data=!3m1!4b1!4m6!3m5!1s0x94f047ed43a4d2dd:0xc57179d696514a97!8m2!3d-25.7511034!4d-53.0606298!16s%2Fg%2F1yy3vkg2x?entry=ttu&g_ep=EgoyMDI2MDEwNy4wIKXMDSoASAFQAw%3D%3D"
    // Adicione mais localizações aqui conforme necessário
    // "outdoor_01": "https://maps.google.com/...",
    // "outdoor_03": "https://maps.google.com/...",
  };

  function updateMapButton() {
    const selectedValue = locationSelect.value;

    if (locationLinks[selectedValue]) {
      mapBtn.href = locationLinks[selectedValue];
      mapBtn.style.display = "inline-flex";
    } else {
      mapBtn.style.display = "none";
    }
  }

  // Verificar estado inicial
  updateMapButton();

  // Ouvir mudanças no select
  locationSelect.addEventListener("change", updateMapButton);
}

