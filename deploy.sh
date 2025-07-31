#!/bin/bash

set -e

# 📁 Entra al subdirectorio de la app Rails
cd vibevoyage/vibevoyage

APP_NAME="vibevoyage" # Cambia esto si tu app tiene otro nombre en Fly.io

echo "✅ Iniciando despliegue Fly.io para Rails + Sidekiq..."

# 🔧 Inicializa Fly si no está creado
if [ ! -f "fly.toml" ]; then
  flyctl launch --name "$APP_NAME" --region mia --no-deploy
fi

# 🔐 Cargar variables de entorno desde .env.prod
echo "🔐 Cargando secrets desde .env.prod..."
while IFS='=' read -r key value
do
  if [[ ! -z "$key" && ! "$key" =~ ^# ]]; then
    flyctl secrets set "$key=$value"
  fi
done < .env.prod

# 🐘 Crear base de datos PostgreSQL (si no existe)
echo "🐘 Configurando base de datos PostgreSQL..."
flyctl postgres create --name "${APP_NAME}-db" --region mia || echo "Base ya existe"
flyctl postgres attach --app "$APP_NAME" "${APP_NAME}-db" || echo "Ya está conectada"

# 🚀 Desplegar la app
echo "🚀 Desplegando aplicación..."
flyctl deploy

# 📈 Escalar procesos: web y Sidekiq (worker)
echo "📈 Escalando procesos web=1, worker=1..."
flyctl scale count web=1
flyctl scale count worker=1

echo "✅ Despliegue completo con Sidekiq activado. Puedes monitorear con:"
echo "   flyctl logs -a $APP_NAME"

