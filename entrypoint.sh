#!/bin/bash
set -e

# Remove o arquivo PID se ele existir (para o servidor não travar)
rm -f /rails/tmp/pids/server.pid

# Executa o comando principal do container (o rails server)
exec "$@"