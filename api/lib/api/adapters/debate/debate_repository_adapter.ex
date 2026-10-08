defmodule Api.Adapters.Debate.DebateRepositoryAdapter do
  @moduledoc """
  Adapts a connection repository (the adaptee) to the domain: calls it for
  the database entity, converts both posts it links into pure
  `Api.Domain.Post` entities (reusing `Api.Adapters.Post.PostRepositoryAdapter`,
  same as `Api.Adapters.Connection.ConnectionRepositoryAdapter` does), then
  assembles a pure `Api.Domain.Debate`.

  Only a `contradicts` connection resolves to a debate — the Step 16 view
  this backs is specifically the "Contradiction / Debate View", not a
  generic single-connection lookup.
  """

  alias Api.Adapters.Post.PostRepositoryAdapter
  alias Api.Domain.Debate

  def get_debate(id, adaptee) do
    case adaptee.get_connection(id) do
      nil -> {:error, :not_found}
      %{relationship_type: "contradicts"} = connection -> {:ok, to_domain(connection)}
      _other -> {:error, :not_found}
    end
  end

  defp to_domain(connection) do
    %Debate{
      id: connection.id,
      relationship_type: connection.relationship_type,
      post_a: PostRepositoryAdapter.to_domain(connection.post),
      post_b: PostRepositoryAdapter.to_domain(connection.related_post),
      inserted_at: connection.inserted_at
    }
  end
end
