defmodule Api.Usecases.Session.RevokeAllRefreshTokens.RevokeAllRefreshTokensUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Session.RevokeAllRefreshTokens.RevokeAllRefreshTokensUsecase`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User

  @enforce_keys [:user]
  defstruct [:user]

  @type t :: %__MODULE__{user: %User{}}
end
