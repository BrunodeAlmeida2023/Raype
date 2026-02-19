// Order Status Page JavaScript
document.addEventListener('turbo:load', () => {
  initializeOrderStatusPage();
});

function initializeOrderStatusPage() {
  const refreshBtn = document.querySelector('.order-refresh-btn');

  if (refreshBtn) {
    refreshBtn.addEventListener('click', (e) => {
      e.preventDefault();
      refreshOrderStatus();
    });
  }

  // Auto-refresh para pedidos pendentes a cada 30 segundos
  const statusBadge = document.querySelector('.order-status-badge');
  if (statusBadge && statusBadge.classList.contains('pending')) {
    startAutoRefresh();
  }
}

function refreshOrderStatus() {
  const refreshBtn = document.querySelector('.order-refresh-btn');
  const icon = refreshBtn.querySelector('i');

  // Adiciona animação de rotação
  icon.classList.add('fa-spin');
  refreshBtn.disabled = true;

  // Recarrega a página após animação
  setTimeout(() => {
    location.reload();
  }, 500);
}

function startAutoRefresh() {
  // Auto-refresh a cada 30 segundos para pedidos pendentes
  const autoRefreshInterval = setInterval(() => {
    const statusBadge = document.querySelector('.order-status-badge');

    // Para o refresh se o status mudou ou página não está mais visível
    if (!statusBadge || !statusBadge.classList.contains('pending') || document.hidden) {
      clearInterval(autoRefreshInterval);
      return;
    }

    console.log('🔄 Auto-refresh: Verificando status do pedido...');
    location.reload();
  }, 30000); // 30 segundos

  // Limpa o interval quando a página é descarregada
  window.addEventListener('beforeunload', () => {
    clearInterval(autoRefreshInterval);
  });
}

// Adiciona feedback visual ao botão de cancelar
document.addEventListener('turbo:load', () => {
  const cancelForm = document.querySelector('form:has(.order-cancel-btn)');

  if (cancelForm) {
    cancelForm.addEventListener('submit', (e) => {
      const cancelBtn = cancelForm.querySelector('.order-cancel-btn');

      // Desabilita botão e mostra loading
      cancelBtn.disabled = true;
      cancelBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Cancelando...';

      // Permite o submit continuar
      return true;
    });
  }
});

// Confirmação customizada (fallback se data-turbo-confirm não funcionar)
document.addEventListener('turbo:load', () => {
  const cancelBtn = document.querySelector('.order-cancel-btn');

  if (cancelBtn && !cancelBtn.form.dataset.turboConfirm) {
    cancelBtn.form.addEventListener('submit', (e) => {
      const confirmed = confirm('Tem certeza que deseja cancelar este orçamento? Esta ação não pode ser desfeita.');

      if (!confirmed) {
        e.preventDefault();
        return false;
      }
    });
  }
});

