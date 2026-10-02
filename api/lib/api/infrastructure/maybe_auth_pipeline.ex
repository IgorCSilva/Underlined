defmodule Api.Infrastructure.MaybeAuthPipeline do
  @moduledoc """
  Like `Api.Infrastructure.Pipeline`, but never 401s on a missing/invalid token —
  used by public endpoints that still want to personalize the response for a
  logged-in caller (e.g. "has this user liked this post?").
  """
  use Guardian.Plug.Pipeline,
    otp_app: :api,
    module: Api.Infrastructure.Guardian,
    error_handler: Api.Infrastructure.ErrorHandler

  plug Guardian.Plug.VerifyHeader, scheme: "Bearer"
  plug Guardian.Plug.LoadResource, allow_blank: true
end
