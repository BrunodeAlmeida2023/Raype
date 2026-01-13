document.addEventListener('DOMContentLoaded', function() {
  const startDateInput = document.getElementById('start_date');
  const endDateInput = document.getElementById('end_date');
  const form = document.getElementById('date-form');

  // Verifica se os elementos existem na página
  if (!startDateInput || !endDateInput || !form) return;

  // Função para adicionar 1 mês a uma data
  function addOneMonth(date) {
    const newDate = new Date(date);
    newDate.setMonth(newDate.getMonth() + 1);
    return newDate;
  }

  // Função para formatar data para YYYY-MM-DD
  function formatDate(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  // Atualiza a data mínima do campo de data final quando a data inicial muda
  startDateInput.addEventListener('change', function() {
    if (this.value) {
      const startDate = new Date(this.value);
      const minEndDate = addOneMonth(startDate);
      endDateInput.min = formatDate(minEndDate);

      // Se a data final atual for menor que a nova data mínima, limpa o campo
      if (endDateInput.value && new Date(endDateInput.value) < minEndDate) {
        endDateInput.value = '';
      }
    }
  });

  // Validação no submit do formulário
  form.addEventListener('submit', function(e) {
    const startDate = new Date(startDateInput.value);
    const endDate = new Date(endDateInput.value);
    const minEndDate = addOneMonth(startDate);

    if (endDate < minEndDate) {
      e.preventDefault();
      alert('A data final deve ser no mínimo 1 mês após a data inicial.');
      return false;
    }
  });

  // Dispara o evento change se já houver um valor inicial
  if (startDateInput.value) {
    startDateInput.dispatchEvent(new Event('change'));
  }
});

