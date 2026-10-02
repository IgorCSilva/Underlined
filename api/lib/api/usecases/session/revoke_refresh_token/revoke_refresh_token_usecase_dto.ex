defmodule Api.Usecases.Session.RevokeRefreshToken.RevokeRefreshTokenUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Session.RevokeRefreshToken.RevokeRefreshTokenUsecase`.
  """

  @enforce_keys [:refresh_token]
  defstruct [:refresh_token]

  @type t :: %__MODULE__{refresh_token: String.t()}
end
