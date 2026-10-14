defmodule Api.Usecases.Chain.AddChainItem.AddChainItemUsecase do
  @moduledoc """
  Appends a post to the end of an idea chain. Only the chain's author may
  add to it.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Chain.AddChainItem.AddChainItemUsecaseDto

  defstruct [:repository]

  def call(
        %AddChainItemUsecaseDto{user: user, chain_id: chain_id, post_id: post_id},
        %__MODULE__{repository: %{adapter: adapter, adaptee: adaptee}}
      ) do
    adapter.add_item(user, chain_id, post_id, adaptee)
  end
end
