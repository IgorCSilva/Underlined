defmodule Api.Usecases.Chain.GetChain.GetChainUsecase do
  @moduledoc """
  A single idea chain, with its items in order. Returns `{:error,
  :not_found}` when it doesn't exist.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Chain.GetChain.GetChainUsecaseDto

  defstruct [:repository]

  def call(%GetChainUsecaseDto{id: id}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.get_chain(id, adaptee)
  end
end
