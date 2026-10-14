defmodule Api.Domain.Graph do
  @moduledoc """
  A user's personal idea graph: their own posts and keywords as nodes,
  connected by the connections and keyword-tags between them as edges.
  """

  defstruct [:nodes, :edges]

  @type t :: %__MODULE__{nodes: [Api.Domain.GraphNode.t()], edges: [Api.Domain.GraphEdge.t()]}
end
