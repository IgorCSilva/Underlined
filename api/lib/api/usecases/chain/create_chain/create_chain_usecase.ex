defmodule Api.Usecases.Chain.CreateChain.CreateChainUsecase do
  @moduledoc """
  Starts a new, empty idea chain titled by its author.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Chain.CreateChain.CreateChainUsecaseDto

  defstruct [:repository]

  def call(%CreateChainUsecaseDto{user: user, title: title}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.create_chain(user, title, adaptee)
  end
end
