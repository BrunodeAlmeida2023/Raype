#!/usr/bin/env ruby
# Script de teste para validar quantity_months

require_relative 'config/environment'

puts "🧪 Teste de Cálculo de quantity_months"
puts "=" * 50

# Simula diferentes cenários de datas
test_cases = [
  { start: Date.new(2026, 3, 12), end: Date.new(2026, 4, 12), expected: 1 },
  { start: Date.new(2026, 3, 12), end: Date.new(2026, 6, 12), expected: 3 },
  { start: Date.new(2026, 3, 12), end: Date.new(2027, 3, 12), expected: 12 },
  { start: Date.new(2026, 1, 1), end: Date.new(2026, 12, 31), expected: 11 },
  { start: Date.new(2026, 3, 15), end: Date.new(2026, 3, 20), expected: 0 } # Menos de 1 mês
]

test_cases.each_with_index do |test, index|
  start_date = test[:start]
  end_date = test[:end]
  
  quantity_months = (end_date.year - start_date.year) * 12 + (end_date.month - start_date.month)
  quantity_months = [quantity_months, 1].max # Garante mínimo de 1
  
  status = quantity_months >= test[:expected] ? "✅" : "❌"
  
  puts "\nTeste #{index + 1}:"
  puts "  Início: #{start_date.strftime('%d/%m/%Y')}"
  puts "  Fim: #{end_date.strftime('%d/%m/%Y')}"
  puts "  Calculado: #{quantity_months} meses"
  puts "  Esperado: #{test[:expected]} meses (mínimo)"
  puts "  Status: #{status}"
end

puts "\n" + "=" * 50
puts "🎯 Testando com Outdoor real (se existir)..."

# Tenta buscar um outdoor do primeiro usuário
user = User.first
if user && user.outdoor
  outdoor = user.outdoor
  if outdoor.selected_start_date && outdoor.selected_end_date
    quantity_months = (outdoor.selected_end_date.year - outdoor.selected_start_date.year) * 12 +
                      (outdoor.selected_end_date.month - outdoor.selected_start_date.month)
    quantity_months = [quantity_months, 1].max
    
    puts "\n✅ Outdoor encontrado:"
    puts "  Usuário: #{user.email}"
    puts "  Tipo: #{outdoor.outdoor_type}"
    puts "  Início: #{outdoor.selected_start_date.strftime('%d/%m/%Y')}"
    puts "  Fim: #{outdoor.selected_end_date.strftime('%d/%m/%Y')}"
    puts "  Meses calculados: #{quantity_months}"
    puts "  Parcelas possíveis: 1 até #{[quantity_months, 12].min}x"
  else
    puts "\n⚠️  Outdoor sem datas selecionadas"
  end
else
  puts "\n⚠️  Nenhum outdoor encontrado no banco"
end

puts "\n" + "=" * 50
puts "✅ Teste concluído!"


