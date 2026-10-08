defmodule ApiWeb.GraphJSON do
  alias Api.Domain.{Graph, GraphEdge, GraphNode}
  alias ApiWeb.PostJSON

  def show(%{graph: graph}), do: %{data: data(graph)}

  def data(%Graph{} = graph) do
    %{
      nodes: Enum.map(graph.nodes, &node_data/1),
      edges: Enum.map(graph.edges, &edge_data/1)
    }
  end

  defp node_data(%GraphNode{type: "post"} = node) do
    %{id: node.id, type: node.type, post: PostJSON.data(node.post)}
  end

  defp node_data(%GraphNode{type: "keyword"} = node) do
    %{id: node.id, type: node.type, keyword: %{id: node.keyword.id, name: node.keyword.name}}
  end

  defp edge_data(%GraphEdge{} = edge) do
    %{id: edge.id, source_id: edge.source_id, target_id: edge.target_id, type: edge.type}
  end
end
