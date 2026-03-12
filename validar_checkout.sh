#!/bin/bash
# Script de Validação do Checkout PIX/BOLETO

echo "🔍 Validação do Checkout - PIX e BOLETO Separados"
echo "=================================================="
echo ""

# 1. Verificar estrutura de arquivos
echo "📂 1. Verificando estrutura de arquivos..."
FILES=(
  "app/views/checkout/new.html.erb"
  "app/views/checkout/show.html.erb"
  "app/javascript/checkout_payment.js"
  "app/controllers/checkout_controller.rb"
  "app/services/asaas_service.rb"
)

for file in "${FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "   ✅ $file"
  else
    echo "   ❌ $file (NÃO ENCONTRADO)"
  fi
done

echo ""
echo "🔎 2. Verificando remoção de PIX_BOLETO agrupado..."

# Verificar se PIX_BOLETO ainda existe nas views
if grep -q 'data-method="PIX_BOLETO"' app/views/checkout/new.html.erb 2>/dev/null; then
  echo "   ❌ PIX_BOLETO ainda encontrado em new.html.erb"
else
  echo "   ✅ PIX_BOLETO removido de new.html.erb"
fi

if grep -q 'data-method="PIX_BOLETO"' app/views/checkout/show.html.erb 2>/dev/null; then
  echo "   ❌ PIX_BOLETO ainda encontrado em show.html.erb"
else
  echo "   ✅ PIX_BOLETO removido de show.html.erb"
fi

echo ""
echo "🎯 3. Verificando métodos separados (PIX e BOLETO)..."

# Verificar se PIX e BOLETO separados existem
if grep -q 'data-method="PIX"' app/views/checkout/new.html.erb 2>/dev/null; then
  echo "   ✅ Card PIX encontrado em new.html.erb"
else
  echo "   ❌ Card PIX NÃO encontrado em new.html.erb"
fi

if grep -q 'data-method="BOLETO"' app/views/checkout/new.html.erb 2>/dev/null; then
  echo "   ✅ Card BOLETO encontrado em new.html.erb"
else
  echo "   ❌ Card BOLETO NÃO encontrado em new.html.erb"
fi

echo ""
echo "📱 4. Verificando IDs dos containers..."

# Verificar IDs específicos
IDS=(
  "pix-options"
  "boleto-options"
  "pix-installments-grid"
  "boleto-installments-grid"
)

for id in "${IDS[@]}"; do
  if grep -q "id=\"$id\"" app/views/checkout/new.html.erb 2>/dev/null; then
    echo "   ✅ #$id encontrado"
  else
    echo "   ❌ #$id NÃO encontrado"
  fi
done

echo ""
echo "💻 5. Verificando JavaScript..."

# Verificar se lógica separada existe
if grep -q "method === 'PIX'" app/javascript/checkout_payment.js 2>/dev/null; then
  echo "   ✅ Lógica para PIX encontrada"
else
  echo "   ❌ Lógica para PIX NÃO encontrada"
fi

if grep -q "method === 'BOLETO'" app/javascript/checkout_payment.js 2>/dev/null; then
  echo "   ✅ Lógica para BOLETO encontrada"
else
  echo "   ❌ Lógica para BOLETO NÃO encontrada"
fi

echo ""
echo "🔧 6. Verificando Controller..."

# Verificar se lógica de PIX_BOLETO foi removida
if grep -q "PIX_BOLETO" app/controllers/checkout_controller.rb 2>/dev/null; then
  echo "   ⚠️  PIX_BOLETO ainda encontrado no controller (pode ser comentário)"
else
  echo "   ✅ PIX_BOLETO removido do controller"
fi

echo ""
echo "🚀 7. Verificando AsaasService..."

# Verificar se método de PIX parcelado existe
if grep -q "create_pix_installments" app/services/asaas_service.rb 2>/dev/null; then
  echo "   ✅ Método create_pix_installments encontrado"
else
  echo "   ❌ Método create_pix_installments NÃO encontrado"
fi

echo ""
echo "=================================================="
echo "✅ Validação Concluída!"
echo ""
echo "📝 Próximos passos:"
echo "   1. Iniciar servidor Rails: rails s"
echo "   2. Acessar checkout e testar PIX à vista"
echo "   3. Testar PIX parcelado"
echo "   4. Testar BOLETO à vista"
echo "   5. Testar BOLETO parcelado"
echo "   6. Verificar logs do Rails e do Asaas"
echo ""

