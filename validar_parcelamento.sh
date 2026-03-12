#!/bin/bash
# Teste Visual do Parcelamento

echo "🔍 Verificação do Parcelamento - Correção quantity_months"
echo "=========================================================="
echo ""

# 1. Verificar se quantity_months está sendo salvo na sessão
echo "✅ 1. Verificando se quantity_months está no HomeController..."
if grep -q "quantity_months: quantity_months" app/controllers/home_controller.rb; then
  echo "   ✅ quantity_months está sendo salvo na sessão"
else
  echo "   ❌ quantity_months NÃO encontrado no controller"
fi

echo ""
echo "✅ 2. Verificando cálculo de quantity_months..."
if grep -q "quantity_months = \[quantity_months, 1\].max" app/controllers/home_controller.rb; then
  echo "   ✅ Validação de mínimo 1 mês implementada"
else
  echo "   ⚠️  Validação de mínimo não encontrada"
fi

echo ""
echo "✅ 3. Verificando validações nas views..."

# new.html.erb
if grep -q "max_installments = 1 if max_installments < 1" app/views/checkout/new.html.erb; then
  echo "   ✅ Validação em new.html.erb encontrada"
else
  echo "   ❌ Validação em new.html.erb NÃO encontrada"
fi

# show.html.erb
if grep -q "max_installments = 1 if max_installments < 1" app/views/checkout/show.html.erb; then
  echo "   ✅ Validação em show.html.erb encontrada"
else
  echo "   ❌ Validação em show.html.erb NÃO encontrada"
fi

echo ""
echo "✅ 4. Verificando limite de 12 parcelas..."
if grep -q "max_installments = \[max_installments, 12\].min" app/views/checkout/new.html.erb; then
  echo "   ✅ Limite de 12 parcelas implementado"
else
  echo "   ⚠️  Limite não encontrado"
fi

echo ""
echo "✅ 5. Verificando logs..."
if grep -q 'Rails.logger.info "🔒 Quantidade de meses: #{quantity_months}"' app/controllers/home_controller.rb; then
  echo "   ✅ Log de debug implementado"
else
  echo "   ⚠️  Log de debug não encontrado (não crítico)"
fi

echo ""
echo "=========================================================="
echo "📊 RESUMO DA VERIFICAÇÃO"
echo "=========================================================="
echo ""

# Conta quantos checks passaram
CHECKS=0
PASSED=0

# Check 1
CHECKS=$((CHECKS + 1))
if grep -q "quantity_months: quantity_months" app/controllers/home_controller.rb; then
  PASSED=$((PASSED + 1))
fi

# Check 2
CHECKS=$((CHECKS + 1))
if grep -q "quantity_months = \[quantity_months, 1\].max" app/controllers/home_controller.rb; then
  PASSED=$((PASSED + 1))
fi

# Check 3
CHECKS=$((CHECKS + 1))
if grep -q "max_installments = 1 if max_installments < 1" app/views/checkout/new.html.erb; then
  PASSED=$((PASSED + 1))
fi

# Check 4
CHECKS=$((CHECKS + 1))
if grep -q "max_installments = 1 if max_installments < 1" app/views/checkout/show.html.erb; then
  PASSED=$((PASSED + 1))
fi

# Check 5
CHECKS=$((CHECKS + 1))
if grep -q "max_installments = \[max_installments, 12\].min" app/views/checkout/new.html.erb; then
  PASSED=$((PASSED + 1))
fi

echo "✅ Checks Passados: $PASSED/$CHECKS"
echo ""

if [ $PASSED -eq $CHECKS ]; then
  echo "🎉 TODAS AS VALIDAÇÕES PASSARAM!"
  echo ""
  echo "📝 Próximos passos para testar:"
  echo "   1. Iniciar servidor: rails s"
  echo "   2. Criar um novo orçamento com período de 3-6 meses"
  echo "   3. Ir para checkout e verificar 'Até Nx' (onde N = meses selecionados)"
  echo "   4. Verificar grid de parcelas (deve ter N opções)"
else
  echo "⚠️  Algumas validações falharam. Revisar implementação."
fi

echo ""
echo "=========================================================="

