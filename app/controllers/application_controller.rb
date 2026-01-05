class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:documento_tipo, :documento_numero])
    devise_parameter_sanitizer.permit(:account_update, keys: [:documento_tipo, :documento_numero])
  end

  private

  def authenticate_admin!
    # Para desenvolvimento, você pode usar isso:
    # authenticate_or_request_with_http_basic do |username, password|
    #   username == "admin" && password == "admin"
    # end

    # Para produção, use devise:
    authenticate_user!
    unless current_user&.admin?
      redirect_to root_path, alert: "Você não tem permissão para acessar esta página."
    end
  end
end
