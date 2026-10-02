defmodule Api.Usecases.Session.RefreshSession.RefreshSessionUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Session.RefreshSession.RefreshSessionUsecase`.
  """

  @enforce_keys [:refresh_token]
  defstruct [:refresh_token]

  @type t :: %__MODULE__{refresh_token: String.t()}
end
