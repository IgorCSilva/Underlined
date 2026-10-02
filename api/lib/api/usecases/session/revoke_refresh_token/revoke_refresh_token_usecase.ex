defmodule Api.Usecases.Session.RevokeRefreshToken.RevokeRefreshTokenUsecase do
  @moduledoc """
  Deletes a single refresh token, invalidating that session.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Session.RevokeRefreshToken.RevokeRefreshTokenUsecaseDto

  defstruct [:repository]

  def call(%RevokeRefreshTokenUsecaseDto{refresh_token: refresh_token}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      })
      when is_binary(refresh_token) do
    adapter.delete_by_hash(refresh_token, adaptee)
    :ok
  end
end
