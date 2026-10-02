defmodule Api.Usecases.EmailConfirmation.ConfirmUser.ConfirmUserUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.EmailConfirmation.ConfirmUser.ConfirmUserUsecase`.
  """

  @enforce_keys [:token]
  defstruct [:token]

  @type t :: %__MODULE__{token: String.t()}
end
