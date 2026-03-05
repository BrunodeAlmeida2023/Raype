function initDateValidation() {
  const startDateInput = document.getElementById('start_date');
  const endDateInput = document.getElementById('end_date');
  const form = document.getElementById('date-form');

  // Verifica se os elementos existem na página
  if (!startDateInput || !endDateInput || !form) return;

  // Verifica se já foi inicializado
  if (startDateInput.dataset.initialized === 'true') return;
  startDateInput.dataset.initialized = 'true';

  let selectedDay = null; // Armazena o dia selecionado na data inicial

  // Função para adicionar N meses a uma data mantendo o mesmo dia
  function addMonths(date, months) {
    const newDate = new Date(date);
    newDate.setMonth(newDate.getMonth() + months);
    return newDate;
  }

  // Função para formatar data para YYYY-MM-DD
  function formatDate(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  // Calcula diferença em meses entre duas datas
  function getMonthsDifference(startDate, endDate) {
    return (endDate.getFullYear() - startDate.getFullYear()) * 12 +
           (endDate.getMonth() - startDate.getMonth());
  }

  // Valida se a data final é válida (mínimo 1 mês, mesmo dia)
  function isValidEndDate(startDate, endDate) {
    // Deve ter o mesmo dia do mês
    if (startDate.getDate() !== endDate.getDate()) {
      return {
        valid: false,
        message: `❌ Dia inválido! Selecione o dia ${startDate.getDate()} do mês.`
      };
    }

    // Calcula diferença em meses
    const monthsDiff = getMonthsDifference(startDate, endDate);

    // Deve ser no mínimo 1 mês
    if (monthsDiff < 1) {
      return {
        valid: false,
        message: '❌ O período deve ser de no mínimo 1 mês'
      };
    }

    return { valid: true, months: monthsDiff };
  }

  // 🔥 BLOQUEIA todos os dias exceto o mesmo dia da data inicial
  function validateDateInput(e) {
    if (!startDateInput.value) return;

    const startDate = new Date(startDateInput.value + 'T00:00:00');
    const selectedDate = new Date(e.target.value + 'T00:00:00');

    // Se o dia selecionado for diferente do dia inicial, BLOQUEIA
    if (selectedDate.getDate() !== startDate.getDate()) {
      e.target.value = ''; // Limpa o campo

      // Mostra alerta
      const hint = endDateInput.parentElement.querySelector('.date-hint');
      if (hint) {
        hint.style.color = '#dc3545';
        hint.innerHTML = `❌ Apenas o dia <strong>${startDate.getDate()}</strong> de cada mês está disponível!`;

        // Remove o alerta após 3 segundos
        setTimeout(() => {
          hint.style.color = '#666';
          hint.innerHTML = `📅 Selecione uma data mantendo sempre o dia <strong>${startDate.getDate()}</strong> do mês`;
        }, 3000);
      }

      return false;
    }

    return true;
  }

  // Configura restrições quando a data inicial é selecionada
  startDateInput.addEventListener('change', function() {
    if (this.value) {
      const startDate = new Date(this.value + 'T00:00:00');
      selectedDay = startDate.getDate();

      // Define data mínima (1 mês depois)
      const minEndDate = addMonths(startDate, 1);
      endDateInput.min = formatDate(minEndDate);

      // Habilita o campo de data final
      endDateInput.disabled = false;

      // Limpa a data final
      endDateInput.value = '';

      // Remove hint antiga
      const oldHint = endDateInput.parentElement.querySelector('.date-hint');
      if (oldHint) oldHint.remove();

      // Cria nova hint
      const hintElement = document.createElement('small');
      hintElement.className = 'date-hint';
      hintElement.style.color = '#666';
      hintElement.style.display = 'block';
      hintElement.style.marginTop = '8px';
      hintElement.style.fontSize = '0.9em';
      hintElement.style.lineHeight = '1.4';
      hintElement.innerHTML = `
        📅 <strong>Apenas o dia ${selectedDay} de cada mês está disponível</strong><br>
        <span style="font-size: 0.85em; color: #888;">
          Exemplos: ${selectedDay.toString().padStart(2, '0')}/${(startDate.getMonth() + 2).toString().padStart(2, '0')}/${startDate.getFullYear()}, 
          ${selectedDay.toString().padStart(2, '0')}/${(startDate.getMonth() + 3).toString().padStart(2, '0')}/${startDate.getFullYear()}, 
          ${selectedDay.toString().padStart(2, '0')}/${(startDate.getMonth() + 4).toString().padStart(2, '0')}/${startDate.getFullYear()}...
        </span>
      `;
      endDateInput.parentElement.appendChild(hintElement);
    }
  });

  // 🔥 BLOQUEIA em tempo real ao digitar/selecionar
  endDateInput.addEventListener('input', function(e) {
    if (!startDateInput.value || !this.value) return;

    const startDate = new Date(startDateInput.value + 'T00:00:00');
    const endDate = new Date(this.value + 'T00:00:00');

    // Se for uma data válida completa, valida
    if (this.value.length === 10) {
      const validation = isValidEndDate(startDate, endDate);
      const hint = endDateInput.parentElement.querySelector('.date-hint');

      if (!validation.valid) {
        // BLOQUEIA - Limpa o campo
        setTimeout(() => {
          this.value = '';
        }, 100);

        if (hint) {
          hint.style.color = '#dc3545';
          hint.innerHTML = validation.message;

          setTimeout(() => {
            hint.style.color = '#666';
            hint.innerHTML = `📅 Selecione uma data mantendo sempre o dia <strong>${startDate.getDate()}</strong> do mês`;
          }, 3000);
        }
      } else {
        // Válido - Mostra feedback positivo
        if (hint) {
          hint.style.color = '#28a745';
          hint.style.fontWeight = '500';
          hint.innerHTML = `✓ Período válido: ${validation.months} ${validation.months === 1 ? 'mês' : 'meses'}`;
        }
      }
    }
  });

  // Validação no change
  endDateInput.addEventListener('change', function() {
    if (!startDateInput.value || !this.value) return;

    const startDate = new Date(startDateInput.value + 'T00:00:00');
    const endDate = new Date(this.value + 'T00:00:00');

    const validation = isValidEndDate(startDate, endDate);

    if (!validation.valid) {
      alert(validation.message);
      this.value = '';
      return;
    }
  });

  // Validação no submit do formulário
  form.addEventListener('submit', function(e) {
    if (!startDateInput.value || !endDateInput.value) {
      e.preventDefault();
      alert('Por favor, selecione ambas as datas (inicial e final).');
      return false;
    }

    const startDate = new Date(startDateInput.value + 'T00:00:00');
    const endDate = new Date(endDateInput.value + 'T00:00:00');

    const validation = isValidEndDate(startDate, endDate);

    if (!validation.valid) {
      e.preventDefault();
      alert(validation.message);
      return false;
    }
  });

  // Desabilita o campo de data final inicialmente
  if (!startDateInput.value) {
    endDateInput.disabled = true;
  }

  // Dispara o evento change se já houver um valor inicial
  if (startDateInput.value) {
    startDateInput.dispatchEvent(new Event('change'));
  }
}

// Inicializar em múltiplos eventos para garantir funcionamento
document.addEventListener('DOMContentLoaded', initDateValidation);
document.addEventListener('turbo:load', initDateValidation);
document.addEventListener('turbo:render', initDateValidation);

