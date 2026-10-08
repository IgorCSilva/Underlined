defmodule Api.Usecases.Chain.ListChains.ListChainsUsecase do
  @moduledoc """
  Every idea chain, newest first, each with its items in order.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Chain.ListChains.ListChainsUsecaseDto

  defstruct [:repository]

  def call(%ListChainsUsecaseDto{}, %__MODULE__{repository: %{adapter: adapter, adaptee: adaptee}}) do
    adapter.list_chains(adaptee)
  end
end
