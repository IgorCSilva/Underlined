defmodule Api.Usecases.Session.RefreshSession.RefreshSessionUsecase do
  @moduledoc """
  Rotates a refresh token: verifies it, deletes it, and issues a new
  access/refresh token pair for its owner. Returns `:error` if the refresh
  token is missing/expired.

  The returned `remember_me?` is the flag the *original* token was issued
  with — callers must carry it into the new cookie's lifetime, or "remember
  me" silently degrades to a session cookie after the first rotation.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Session.CreateSession.{CreateSessionUsecase, CreateSessionUsecaseDto}
  alias Api.Usecases.Session.RefreshSession.RefreshSessionUsecaseDto

  defstruct [:repository]

  def call(%RefreshSessionUsecaseDto{refresh_token: refresh_token}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee} = repository
      })
      when is_binary(refresh_token) do
    case adapter.find_valid(refresh_token, adaptee) do
      {stored, user} ->
        adapter.delete(stored, adaptee)

        {:ok, access_token, new_refresh_token} =
          CreateSessionUsecase.call(
            %CreateSessionUsecaseDto{user: user, remember_me: stored.remember_me},
            %CreateSessionUsecase{repository: repository}
          )

        {:ok, access_token, new_refresh_token, stored.remember_me}

      nil ->
        :error
    end
  end
end
