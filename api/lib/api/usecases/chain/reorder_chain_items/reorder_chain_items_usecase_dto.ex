defmodule Api.Usecases.Chain.ReorderChainItems.ReorderChainItemsUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Chain.ReorderChainItems.ReorderChainItemsUsecase`.
  """

  @enforce_keys [:user, :chain_id, :item_ids]
  defstruct [:user, :chain_id, :item_ids]

  @type t :: %__MODULE__{
          user: Api.Domain.User.t(),
          chain_id: Ecto.UUID.t(),
          item_ids: [Ecto.UUID.t()]
        }
end
