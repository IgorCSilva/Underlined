defmodule Api.Usecases.User.GetUserByEmailAndPassword.GetUserByEmailAndPasswordUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.User.GetUserByEmailAndPassword.GetUserByEmailAndPasswordUsecase`.
  """

  @enforce_keys [:email, :password]
  defstruct [:email, :password]

  @type t :: %__MODULE__{email: String.t(), password: String.t()}
end
