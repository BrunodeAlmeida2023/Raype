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

  let currentPaymentMethod = ''; // PIX_BOLETO ou CARD
  let currentPaymentType = ''; // PIX, BOLETO, CREDIT_CARD, DEBIT_CARD
  let currentInstallments = 1;

  // Função para resetar seleção
  function resetAllSelections() {
    paymentCards.forEach(c => c.classList.remove('selected'));

    // Esconde todos os containers de opções
    const pixBoletoOptions = document.getElementById('pix-boleto-options');
    const cardOptions = document.getElementById('card-options');
    const pixBoletoGrid = document.getElementById('pix-boleto-installments-grid');

    if (pixBoletoOptions) pixBoletoOptions.classList.add('hidden-data');
    if (cardOptions) cardOptions.classList.add('hidden-data');
    if (pixBoletoGrid) pixBoletoGrid.classList.add('hidden-data');

    // Resetar cards de tipo de pagamento
    document.querySelectorAll('.payment-type-option-card').forEach(card => {
      card.classList.remove('active');
    });

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

  // Selecionar método de pagamento principal (PIX_BOLETO ou CARD)
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
      if (method === 'PIX_BOLETO') {
        console.log('💰 Mostrando opções de PIX/BOLETO');
        const pixBoletoOptions = document.getElementById('pix-boleto-options');
        console.log('📦 Container pix-boleto-options:', pixBoletoOptions);

        if (pixBoletoOptions) {
          console.log('✅ Removendo classe hidden-data');
          pixBoletoOptions.classList.remove('hidden-data');
        } else {
          console.error('❌ Container pix-boleto-options não encontrado!');
        }

        // Define BOLETO como padrão (será usado no backend)
        currentPaymentType = 'BOLETO';
        paymentTypeInput.value = 'BOLETO';
        paymentMethodInput.value = 'BOLETO';

        // Ativa "À Vista" por padrão
        const avistaCard = document.querySelector('.payment-mode-card[data-mode="avista"][data-payment-type="pix-boleto"]');
        if (avistaCard) avistaCard.classList.add('active');

        currentInstallments = 1;
        installmentsInput.value = 1;

        // Habilita botão já que tem seleção padrão
        submitButton.disabled = false;
        submitButton.classList.add('enabled');

      } else if (method === 'CARD') {
        const cardOptions = document.getElementById('card-options');
        if (cardOptions) cardOptions.classList.remove('hidden-data');

        // Define CREDIT_CARD como padrão (Asaas decide crédito ou débito)
        currentPaymentType = 'CREDIT_CARD';
        paymentTypeInput.value = 'CREDIT_CARD';
        paymentMethodInput.value = 'CREDIT_CARD';

        currentInstallments = 1;
        installmentsInput.value = 1;

        // Habilita botão imediatamente
        submitButton.disabled = false;
        submitButton.classList.add('enabled');
      }

      console.log('✅ Método selecionado:', method);
    });
  });

  // Event listener para tipo de cartão REMOVIDO - não existe mais na UI

  // Selecionar modo de pagamento (À Vista ou Parcelado) para PIX/BOLETO
  document.querySelectorAll('.payment-mode-card[data-payment-type="pix-boleto"]').forEach(modeCard => {
    modeCard.addEventListener('click', function(e) {
      e.stopPropagation();

      const mode = this.getAttribute('data-mode');
      const paymentType = this.getAttribute('data-payment-type');

      // Remove active de todos os cards do mesmo tipo
      document.querySelectorAll(`.payment-mode-card[data-payment-type="${paymentType}"]`).forEach(c => {
        c.classList.remove('active');
      });

      // Adiciona active no clicado
      this.classList.add('active');

      // Mostra/esconde grid de parcelas
      const pixBoletoGrid = document.getElementById('pix-boleto-installments-grid');

      if (mode === 'parcelado' && pixBoletoGrid) {
        pixBoletoGrid.classList.remove('hidden-data');
        setTimeout(() => {
          pixBoletoGrid.style.opacity = '1';
          pixBoletoGrid.style.transform = 'translateY(0)';
        }, 10);
      } else if (pixBoletoGrid) {
        pixBoletoGrid.classList.add('hidden-data');
        currentInstallments = 1;
        installmentsInput.value = 1;
      }

      console.log('📋 Modo:', mode);
    });
  });

  // Selecionar parcela específica
  document.querySelectorAll('.installment-card[data-payment-type="pix-boleto"]').forEach(installmentCard => {
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

      console.log('💰 Parcelas selecionadas:', installments);
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

