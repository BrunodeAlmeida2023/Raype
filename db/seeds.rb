# Criar usuário admin para acesso ao Sidekiq e Flipper
# Execute com: rails db:seed

if Rails.env.development?
  admin = User.find_or_initialize_by(email: 'admin@raype.dev')
  if admin.new_record?
    admin.password = 'password123'
    admin.password_confirmation = 'password123'
    admin.documento_tipo = 'cpf'
    admin.documento_numero = '11144477735'  # CPF válido
    admin.admin = true
    admin.confirmed_at = Time.now  # Confirmar automaticamente

    if admin.save
      puts "✅ Usuário admin criado com sucesso!"
      puts "   Email: admin@raype.dev"
      puts "   Senha: password123"
      puts "   CPF: 111.444.777-35"
    else
      puts "❌ Erro ao criar usuário admin:"
      admin.errors.full_messages.each do |msg|
        puts "   - #{msg}"
      end
    end
  else
    admin.documento_tipo ||= 'cpf'
    admin.documento_numero ||= '11144477735'
    admin.admin = true
    admin.confirmed_at ||= Time.now

    if admin.save
      puts "✅ Usuário admin atualizado!"
      puts "   Email: admin@raype.dev"
    else
      puts "❌ Erro ao atualizar usuário admin:"
      admin.errors.full_messages.each do |msg|
        puts "   - #{msg}"
      end
    end
  end
else
  puts "⚠️  Seeds de desenvolvimento só rodam em ambiente development"
end

