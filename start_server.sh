#!/bin/bash

echo "🧹 Limpando processos e portas..."
pkill -9 -f foreman 2>/dev/null
pkill -9 -f puma 2>/dev/null
pkill -9 -f sidekiq 2>/dev/null
sudo lsof -ti:3000 2>/dev/null | xargs sudo kill -9 2>/dev/null
rm -f tmp/pids/server.pid

echo "✅ Tudo limpo! Iniciando servidor..."
bin/dev

