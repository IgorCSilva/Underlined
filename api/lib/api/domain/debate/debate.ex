defmodule Api.Domain.Debate do
  @moduledoc """
  Pure business-rule entity for the Step 16 debate view: a single
  `contradicts` connection, resolved to both full posts it links. Holds no
  knowledge of Ecto, Postgres, or any other persistence detail.
  """

  defstruct [:id, :relationship_type, :post_a, :post_b, :inserted_at]

  @type t :: %__MODULE__{
          id: String.t(),
          relationship_type: String.t(),
          post_a: Api.Domain.Post.t(),
          post_b: Api.Domain.Post.t(),
          inserted_at: DateTime.t() | nil
        }
end
