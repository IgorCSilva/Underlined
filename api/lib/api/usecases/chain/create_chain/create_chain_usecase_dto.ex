defmodule Api.Usecases.Chain.CreateChain.CreateChainUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Chain.CreateChain.CreateChainUsecase`.
  """

  @enforce_keys [:user, :title]
  defstruct [:user, :title]

  @type t :: %__MODULE__{user: Api.Domain.User.t(), title: String.t()}
end
