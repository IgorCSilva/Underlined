defmodule Api.Usecases.User.RegisterUser.RegisterUserUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.User.RegisterUser.RegisterUserUsecase`.
  """

  @enforce_keys [:attrs]
  defstruct [:attrs]

  @type t :: %__MODULE__{attrs: map()}
end
