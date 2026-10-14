defmodule Api.Domain.GraphEdge do
  @moduledoc """
  A single edge in a `Api.Domain.Graph`, linking `source_id` to `target_id`.
  `type` is either a connection's relationship type (e.g. "contradicts")
  for a post-to-post edge, or the literal `"keyword"` for a post-to-keyword
  edge.
  """

  defstruct [:id, :source_id, :target_id, :type]

  @type t :: %__MODULE__{
          id: String.t(),
          source_id: Ecto.UUID.t(),
          target_id: Ecto.UUID.t(),
          type: String.t()
        }
end
