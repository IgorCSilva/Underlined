defmodule Api.Accounts.Pipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :api,
    module: Api.Accounts.Guardian,
    error_handler: Api.Accounts.ErrorHandler

  plug Guardian.Plug.VerifyHeader, scheme: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
