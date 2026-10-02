defmodule Api.Infrastructure.MaybeAuthErrorHandler do
  @moduledoc """
  Used by `Api.Infrastructure.MaybeAuthPipeline`. `Guardian.Plug.VerifyHeader`
  calls the error handler (and sends its response) as soon as it finds a
  token that's invalid or expired — regardless of `allow_blank` on the
  `LoadResource` plug further down. On an optionally-authenticated route
  that should degrade to anonymous, not 401, so this swallows the error
  instead of responding with it.
  """

  @behaviour Guardian.Plug.ErrorHandler

  @impl true
  def auth_error(conn, _error, _opts), do: conn
end
