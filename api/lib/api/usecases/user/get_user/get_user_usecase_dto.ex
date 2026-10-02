defmodule Api.Usecases.User.GetUser.GetUserUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.User.GetUser.GetUserUsecase`.
  """

  @enforce_keys [:id]
  defstruct [:id]

  @type t :: %__MODULE__{id: Ecto.UUID.t()}
end
