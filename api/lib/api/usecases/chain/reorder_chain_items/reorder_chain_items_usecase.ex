defmodule Api.Usecases.Chain.ReorderChainItems.ReorderChainItemsUsecase do
  @moduledoc """
  Reorders an idea chain's items to match a new, complete ordering. Only
  the chain's author may reorder it.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Chain.ReorderChainItems.ReorderChainItemsUsecaseDto

  defstruct [:repository]

  def call(
        %ReorderChainItemsUsecaseDto{user: user, chain_id: chain_id, item_ids: item_ids},
        %__MODULE__{repository: %{adapter: adapter, adaptee: adaptee}}
      ) do
    adapter.reorder_items(user, chain_id, item_ids, adaptee)
  end
end
