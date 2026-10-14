defmodule Api.Usecases.Chain.AddChainItem.AddChainItemUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Chain.AddChainItem.AddChainItemUsecase`.
  """

  @enforce_keys [:user, :chain_id, :post_id]
  defstruct [:user, :chain_id, :post_id]

  @type t :: %__MODULE__{
          user: Api.Domain.User.t(),
          chain_id: Ecto.UUID.t(),
          post_id: Ecto.UUID.t()
        }
end
