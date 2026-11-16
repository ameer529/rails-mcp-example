Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  match "mcp" => "mcp#handle", via: %i[get post delete]
end
