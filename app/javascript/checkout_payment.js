// Checkout - Seleção de Métodos de Pagamento
document.addEventListener('DOMContentLoaded', function() {
  console.log('🔄 Checkout Payment JS carregado');

  // Só executa se estiver na página de checkout
  const paymentForm = document.getElementById('payment-form');
  if (!paymentForm) {
    console.log('❌ Não está na página de checkout');
    return;
  }

  console.log('✅ Página de checkout detectada');

  const paymentCards = document.querySelectorAll('.payment-method-card');
  const paymentMethodInput = document.getElementById('selected-payment-method');
  const paymentTypeInput = document.getElementById('selected-payment-type');
  const installmentsInput = document.getElementById('selected-installments');
  const submitButton = document.getElementById('checkout-submit');

  console.log('📋 Elementos encontrados:', {
    paymentCards: paymentCards.length,
    paymentMethodInput: !!paymentMethodInput,
    paymentTypeInput: !!paymentTypeInput,
    installmentsInput: !!installmentsInput,
    submitButton: !!submitButton
  });

  let currentPaymentMethod = ''; // PIX, BOLETO ou CARD
  let currentInstallments = 1;

  // Função para resetar seleção
  function resetAllSelections() {
    paymentCards.forEach(c => c.classList.remove('selected'));

    // Esconde todos os containers de opções
    const pixOptions = document.getElementById('pix-options');
    const boletoOptions = document.getElementById('boleto-options');
    const pixGrid = document.getElementById('pix-installments-grid');
    const boletoGrid = document.getElementById('boleto-installments-grid');

    if (pixOptions) pixOptions.classList.add('hidden-data');
    if (boletoOptions) boletoOptions.classList.add('hidden-data');
    if (pixGrid) pixGrid.classList.add('hidden-data');
    if (boletoGrid) boletoGrid.classList.add('hidden-data');

    // Resetar cards de modo de pagamento
    document.querySelectorAll('.payment-mode-card').forEach(card => {
      card.classList.remove('active');
    });

    // Resetar cards de parcelas
    document.querySelectorAll('.installment-card').forEach(card => {
      card.classList.remove('selected');
    });

    // Desabilita o botão
    submitButton.disabled = true;
    submitButton.classList.remove('enabled');
  }

  // Selecionar método de pagamento principal (PIX ou BOLETO)
  paymentCards.forEach(card => {
    card.addEventListener('click', function() {
      const method = this.getAttribute('data-method');
      console.log('🎯 Card clicado:', method);

      // Remove seleção anterior
      resetAllSelections();

      // Adiciona seleção atual
      this.classList.add('selected');
      currentPaymentMethod = method;

      // Mostra opções específicas
      if (method === 'PIX') {
        console.log('💰 Mostrando opções de PIX');
        const pixOptions = document.getElementById('pix-options');

        if (pixOptions) {
          pixOptions.classList.remove('hidden-data');
        } else {
          console.error('❌ Container pix-options não encontrado!');
        }

        // Define PIX no campo hidden
        paymentMethodInput.value = 'PIX';
        paymentTypeInput.value = 'PIX';

        // Ativa "À Vista" por padrão
        const avistaCard = document.querySelector('.payment-mode-card[data-mode="avista"][data-payment-type="pix"]');
        if (avistaCard) avistaCard.classList.add('active');

        currentInstallments = 1;
        installmentsInput.value = 1;

        // Habilita botão já que tem seleção padrão
        submitButton.disabled = false;
        submitButton.classList.add('enabled');

      } else if (method === 'BOLETO') {
        console.log('💰 Mostrando opções de BOLETO');
        const boletoOptions = document.getElementById('boleto-options');

        if (boletoOptions) {
          boletoOptions.classList.remove('hidden-data');
        } else {
          console.error('❌ Container boleto-options não encontrado!');
        }

        // Define BOLETO no campo hidden
        paymentMethodInput.value = 'BOLETO';
        paymentTypeInput.value = 'BOLETO';

        // Ativa "À Vista" por padrão
        const avistaCard = document.querySelector('.payment-mode-card[data-mode="avista"][data-payment-type="boleto"]');
        if (avistaCard) avistaCard.classList.add('active');

        currentInstallments = 1;
        installmentsInput.value = 1;

        // Habilita botão já que tem seleção padrão
        submitButton.disabled = false;
        submitButton.classList.add('enabled');
      }

      console.log('✅ Método selecionado:', method);
    });
  });

  // Selecionar modo de pagamento (À Vista ou Parcelado) para PIX
  document.querySelectorAll('.payment-mode-card[data-payment-type="pix"]').forEach(modeCard => {
    modeCard.addEventListener('click', function(e) {
      e.stopPropagation();

      const mode = this.getAttribute('data-mode');
      const paymentType = this.getAttribute('data-payment-type');

      // Remove active de todos os cards PIX
      document.querySelectorAll(`.payment-mode-card[data-payment-type="${paymentType}"]`).forEach(c => {
        c.classList.remove('active');
      });

      // Adiciona active no clicado
      this.classList.add('active');

      // Mostra/esconde grid de parcelas PIX
      const pixGrid = document.getElementById('pix-installments-grid');

      if (mode === 'parcelado' && pixGrid) {
        pixGrid.classList.remove('hidden-data');
        setTimeout(() => {
          pixGrid.style.opacity = '1';
          pixGrid.style.transform = 'translateY(0)';
        }, 10);
      } else if (pixGrid) {
        pixGrid.classList.add('hidden-data');
        currentInstallments = 1;
        installmentsInput.value = 1;
      }

      console.log('📋 Modo PIX:', mode);
    });
  });

  // Selecionar modo de pagamento (À Vista ou Parcelado) para BOLETO
  document.querySelectorAll('.payment-mode-card[data-payment-type="boleto"]').forEach(modeCard => {
    modeCard.addEventListener('click', function(e) {
      e.stopPropagation();

      const mode = this.getAttribute('data-mode');
      const paymentType = this.getAttribute('data-payment-type');

      // Remove active de todos os cards BOLETO
      document.querySelectorAll(`.payment-mode-card[data-payment-type="${paymentType}"]`).forEach(c => {
        c.classList.remove('active');
      });

      // Adiciona active no clicado
      this.classList.add('active');

      // Mostra/esconde grid de parcelas BOLETO
      const boletoGrid = document.getElementById('boleto-installments-grid');

      if (mode === 'parcelado' && boletoGrid) {
        boletoGrid.classList.remove('hidden-data');
        setTimeout(() => {
          boletoGrid.style.opacity = '1';
          boletoGrid.style.transform = 'translateY(0)';
        }, 10);
      } else if (boletoGrid) {
        boletoGrid.classList.add('hidden-data');
        currentInstallments = 1;
        installmentsInput.value = 1;
      }

      console.log('📋 Modo BOLETO:', mode);
    });
  });

  // Selecionar parcela específica para PIX
  document.querySelectorAll('.installment-card[data-payment-type="pix"]').forEach(installmentCard => {
    installmentCard.addEventListener('click', function(e) {
      e.stopPropagation();

      const installments = this.getAttribute('data-installments');
      const paymentType = this.getAttribute('data-payment-type');

      // Remove seleção anterior
      document.querySelectorAll(`.installment-card[data-payment-type="${paymentType}"]`).forEach(c => {
        c.classList.remove('selected');
      });

      // Adiciona seleção
      this.classList.add('selected');

      currentInstallments = parseInt(installments);
      installmentsInput.value = installments;

      // Feedback visual
      this.style.transform = 'scale(0.95)';
      setTimeout(() => {
        this.style.transform = 'scale(1)';
      }, 150);

      console.log('💰 Parcelas PIX selecionadas:', installments);
    });
  });

  // Selecionar parcela específica para BOLETO
  document.querySelectorAll('.installment-card[data-payment-type="boleto"]').forEach(installmentCard => {
    installmentCard.addEventListener('click', function(e) {
      e.stopPropagation();

      const installments = this.getAttribute('data-installments');
      const paymentType = this.getAttribute('data-payment-type');

      // Remove seleção anterior
      document.querySelectorAll(`.installment-card[data-payment-type="${paymentType}"]`).forEach(c => {
        c.classList.remove('selected');
      });

      // Adiciona seleção
      this.classList.add('selected');

      currentInstallments = parseInt(installments);
      installmentsInput.value = installments;

      // Feedback visual
      this.style.transform = 'scale(0.95)';
      setTimeout(() => {
        this.style.transform = 'scale(1)';
      }, 150);

      console.log('💰 Parcelas BOLETO selecionadas:', installments);
    });
  });

  // Validação no submit
  document.getElementById('payment-form').addEventListener('submit', function(e) {
    if (!paymentMethodInput.value) {
      e.preventDefault();
      alert('Por favor, selecione um método de pagamento.');
      return false;
    }

    console.log('🚀 Enviando pagamento:');
    console.log('   Método:', paymentMethodInput.value);
    console.log('   Tipo:', paymentTypeInput.value);
    console.log('   Parcelas:', installmentsInput.value);

    return true;
  });
});

