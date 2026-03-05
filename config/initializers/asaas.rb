# config/initializers/asaas.rb
# Configuração do Asaas via variáveis de ambiente
Rails.configuration.asaas = {
  api_key: ENV.fetch('ASAAS_API_KEY', ''),
  url: ENV.fetch('ASAAS_API_URL', 'https://api.asaas.com/v3')
}

# Validação em produção
if Rails.env.production? && Rails.configuration.asaas[:api_key].blank?
  Rails.logger.error "⚠️  ASAAS_API_KEY não configurada! Pagamentos não funcionarão."
end
