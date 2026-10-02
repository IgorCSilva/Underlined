defmodule Api.Usecases.Session.CreateSession.CreateSessionUsecase do
  @moduledoc """
  Issues an access token (JWT, via Guardian) and a refresh token for a user.
  `remember_me` controls how long the refresh token stays valid.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User
  alias Api.Usecases.Session.CreateSession.CreateSessionUsecaseDto

  defstruct [:repository]

  def call(%CreateSessionUsecaseDto{user: %User{} = user, remember_me: remember_me?}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    {:ok, access_token, _claims} = Api.Infrastructure.Guardian.encode_and_sign(user)
    refresh_token = adapter.insert(user, remember_me?, adaptee)
    {:ok, access_token, refresh_token}
  end
end
