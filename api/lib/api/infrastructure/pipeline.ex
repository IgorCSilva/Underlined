defmodule Api.Infrastructure.Pipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :api,
    module: Api.Infrastructure.Guardian,
    error_handler: Api.Infrastructure.ErrorHandler

  plug Guardian.Plug.VerifyHeader, scheme: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
