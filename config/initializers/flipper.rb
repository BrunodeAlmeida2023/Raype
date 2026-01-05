require 'flipper'
require 'flipper/adapters/active_record'

Flipper.configure do |config|
  config.adapter { Flipper::Adapters::ActiveRecord.new }
end

# Pré-carregar features comuns (opcional)
Rails.application.config.after_initialize do
  # Flipper.enable(:new_feature) # exemplo
end

