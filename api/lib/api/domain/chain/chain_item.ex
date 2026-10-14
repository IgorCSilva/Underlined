defmodule Api.Domain.ChainItem do
  @moduledoc """
  Pure business-rule entity for one step of an idea chain: a post plus its
  0-based position in the chain's order.
  """

  defstruct [:id, :position, :post]

  @type t :: %__MODULE__{
          id: String.t(),
          position: non_neg_integer(),
          post: Api.Domain.Post.t()
        }
end
