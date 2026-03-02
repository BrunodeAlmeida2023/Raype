# frozen_string_literal: true

# Configuração do Resend para envio de e-mails
if Rails.env.production?
  # Em produção, a API key é obrigatória
  if ENV['RESEND_API_KEY'].blank?
    Rails.logger.warn "⚠️  AVISO: RESEND_API_KEY não configurada. E-mails não serão enviados!"
  else
    Resend.api_key = ENV['RESEND_API_KEY']
    Rails.logger.info "✅ Resend configurado com sucesso"
  end
else
  # Em desenvolvimento/test, permite funcionar sem a key (mas avisa)
  if ENV['RESEND_API_KEY'].present?
    Resend.api_key = ENV['RESEND_API_KEY']
    Rails.logger.info "✅ Resend configurado para ambiente #{Rails.env}"
  else
    Rails.logger.warn "⚠️  Resend: RESEND_API_KEY não configurada. Configure para testar envio real de e-mails."
  end
end

