defmodule Api.Adapters.Graph.GraphRepositoryAdapter do
  @moduledoc """
  Adapts a graph repository (the adaptee) to the domain: calls it for the
  database entities, converts the posts into pure `Api.Domain.Post`
  entities (reusing `Api.Adapters.Post.PostRepositoryAdapter`, same as
  `Api.Adapters.Connection.ConnectionRepositoryAdapter` does), then
  assembles the post/keyword nodes and connection/keyword edges of a pure
  `Api.Domain.Graph`.
  """

  alias Api.Adapters.Post.PostRepositoryAdapter
  alias Api.Domain.{Graph, GraphEdge, GraphNode}

  def get_graph(user_id, adaptee) do
    %{posts: db_posts, connections: db_connections} = adaptee.get_graph(user_id)

    posts = Enum.map(db_posts, &PostRepositoryAdapter.to_domain/1)
    build_graph(posts, db_connections)
  end

  defp build_graph(posts, db_connections) do
    post_nodes = Enum.map(posts, &%GraphNode{id: &1.id, type: "post", post: &1})

    keywords = posts |> Enum.flat_map(& &1.keywords) |> Enum.uniq_by(& &1.id)
    keyword_nodes = Enum.map(keywords, &%GraphNode{id: &1.id, type: "keyword", keyword: &1})

    keyword_edges =
      for post <- posts, keyword <- post.keywords do
        %GraphEdge{
          id: "#{post.id}:#{keyword.id}",
          source_id: post.id,
          target_id: keyword.id,
          type: "keyword"
        }
      end

    connection_edges =
      Enum.map(db_connections, fn connection ->
        %GraphEdge{
          id: connection.id,
          source_id: connection.post_id,
          target_id: connection.related_post_id,
          type: connection.relationship_type
        }
      end)

    %Graph{nodes: post_nodes ++ keyword_nodes, edges: connection_edges ++ keyword_edges}
  end
end
