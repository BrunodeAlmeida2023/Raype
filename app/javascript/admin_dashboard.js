// Admin Dashboard - Funcionalidades interativas

// Auto-atualizar estatísticas (opcional)
export function refreshStats() {
  const statsCards = document.querySelectorAll('.admin-stat-card');

  statsCards.forEach(card => {
    card.addEventListener('mouseenter', function() {
      this.style.transition = 'transform 0.2s ease';
    });
  });
}

// Destacar linha da tabela ao passar o mouse
export function initTableHighlight() {
  const tables = document.querySelectorAll('.admin-table');

  tables.forEach(table => {
    const rows = table.querySelectorAll('tbody tr');

    rows.forEach(row => {
      row.addEventListener('mouseenter', function() {
        this.style.backgroundColor = '#f8f9fa';
      });

      row.addEventListener('mouseleave', function() {
        if (!this.classList.contains('admin-row-expired')) {
          this.style.backgroundColor = '';
        }
      });
    });
  });
}

// Adicionar animação nos cards ao carregar
export function animateCards() {
  const cards = document.querySelectorAll('.admin-stat-card, .admin-card');

  cards.forEach((card, index) => {
    setTimeout(() => {
      card.style.opacity = '0';
      card.style.transform = 'translateY(20px)';
      card.style.transition = 'all 0.3s ease';

      setTimeout(() => {
        card.style.opacity = '1';
        card.style.transform = 'translateY(0)';
      }, 50);
    }, index * 50);
  });
}

// Tooltip para badges
export function initBadgeTooltips() {
  const badges = document.querySelectorAll('.admin-badge');

  badges.forEach(badge => {
    badge.title = badge.textContent.trim();
  });
}

// Filtro rápido de tabela (busca)
export function initTableSearch(searchInputId, tableId) {
  const searchInput = document.getElementById(searchInputId);
  const table = document.getElementById(tableId);

  if (!searchInput || !table) return;

  searchInput.addEventListener('input', function() {
    const searchTerm = this.value.toLowerCase();
    const rows = table.querySelectorAll('tbody tr');

    rows.forEach(row => {
      const text = row.textContent.toLowerCase();
      row.style.display = text.includes(searchTerm) ? '' : 'none';
    });
  });
}

// Inicialização de todas as funcionalidades
function initDashboard() {
  refreshStats();
  initTableHighlight();
  initBadgeTooltips();

  // Animação apenas no carregamento inicial
  if (!sessionStorage.getItem('dashboard-loaded')) {
    animateCards();
    sessionStorage.setItem('dashboard-loaded', 'true');
  }
}

// Event listeners
document.addEventListener('DOMContentLoaded', initDashboard);
document.addEventListener('turbo:load', initDashboard);

// Limpar flag ao sair da página
document.addEventListener('turbo:before-visit', () => {
  sessionStorage.removeItem('dashboard-loaded');
});

