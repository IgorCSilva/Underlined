defmodule Api.Usecases.User.GetUserByEmail.GetUserByEmailUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.User.GetUserByEmail.GetUserByEmailUsecase`.
  """

  @enforce_keys [:email]
  defstruct [:email]

  @type t :: %__MODULE__{email: String.t()}
end
