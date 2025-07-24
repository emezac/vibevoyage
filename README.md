# VibeVoyage

Prototipo funcional para el Qloo Global Hackathon.

## Estructura del proyecto

- `docs/`: Documentación, diseño UI y PRD.
- `vibevoyage/`: Aplicación Rails 8 + Tailwind + PostgreSQL.

## Requisitos de entorno

- Ruby 3.3+
- Rails 8.0+
- PostgreSQL

## Primeros pasos

1. Instala dependencias:
   ```bash
   cd vibevoyage
   bundle install
   rails db:create
   rails db:migrate
   rails server
   ```
2. Accede a la app en `http://localhost:3000`


## Registro de usuarios: Web y API

El registro de usuarios soporta ambos flujos:

- **Web (HTML):**
  - Usa el formulario Devise estándar.
  - Tras crear el usuario, redirige según el flujo normal de Rails.

- **API (JSON):**
  - Envía la petición con el header `Accept: application/json`.
  - Si el usuario se crea correctamente, responde con status `201 Created` y datos JSON.
  - Si hay errores, responde con status `422 Unprocessable Entity` y detalles.

### Ejemplo API (cURL)
```bash
curl -X POST http://localhost:3000/users \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"user":{"email":"test@example.com","password":"password123","password_confirmation":"password123"}}'
```

### Ejemplo Web (Rails form)
```erb
<%= form_with(model: User.new, url: user_registration_path) do |f| %>
  <%= f.email_field :email %>
  <%= f.password_field :password %>
  <%= f.submit "Crear Usuario" %>
<% end %>
```

## Más información

Consulta la documentación en `docs/` y el README específico en `vibevoyage/README.md`.