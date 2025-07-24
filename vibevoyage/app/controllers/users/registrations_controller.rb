class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :html, :json

  protected

  def after_sign_up_path_for(resource)
    # Para requests HTML, usa el comportamiento por defecto de Devise
    super(resource)
  end

  def respond_with(resource, _opts = {})
    if request.format.json?
      # Respuesta para API (JSON)
      if resource.persisted?
        render json: {
          status: 'success',
          message: 'Usuario creado exitosamente',
          user: {
            id: resource.id,
            email: resource.email,
            created_at: resource.created_at
          }
        }, status: :created
      else
        render json: {
          status: 'error',
          message: 'No se pudo crear el usuario',
          errors: resource.errors.full_messages
        }, status: :unprocessable_entity
      end
    else
      # Respuesta para web (HTML) - comportamiento normal de Devise
      super
    end
  end
end
