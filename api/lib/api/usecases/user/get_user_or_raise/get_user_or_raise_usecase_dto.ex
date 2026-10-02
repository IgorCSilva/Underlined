defmodule Api.Usecases.User.GetUserOrRaise.GetUserOrRaiseUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.User.GetUserOrRaise.GetUserOrRaiseUsecase`.
  """

  @enforce_keys [:id]
  defstruct [:id]

  @type t :: %__MODULE__{id: Ecto.UUID.t()}
end
