defmodule Api.Usecases.Session.RevokeAllRefreshTokens.RevokeAllRefreshTokensUsecase do
  @moduledoc """
  Deletes every refresh token belonging to a user, invalidating all of
  their sessions.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User
  alias Api.Usecases.Session.RevokeAllRefreshTokens.RevokeAllRefreshTokensUsecaseDto

  defstruct [:repository]

  def call(%RevokeAllRefreshTokensUsecaseDto{user: %User{} = user}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.delete_all_for_user(user, adaptee)
    :ok
  end
end
