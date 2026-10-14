defmodule Api.Usecases.Chain.GetChain.GetChainUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Chain.GetChain.GetChainUsecase`.
  """

  @enforce_keys [:id]
  defstruct [:id]

  @type t :: %__MODULE__{id: Ecto.UUID.t()}
end
