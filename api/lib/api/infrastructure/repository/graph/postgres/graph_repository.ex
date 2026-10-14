defmodule Api.Infrastructure.Repository.Graph.Postgres.GraphRepository do
  @moduledoc """
  Postgres-backed data access for a user's personal idea graph: their own
  posts (with keywords preloaded) and the connections between those posts.
  """

  import Ecto.Query, warn: false

  alias Api.Infrastructure.Repository.Connection.Postgres.Connection
  alias Api.Infrastructure.Repository.Post.Postgres.Post
  alias Api.Repo

  @post_preloads [:book, :passage, :keywords, :user]

  @doc """
  The raw posts and connections behind `user_id`'s idea graph. Returns
  `%{posts: [], connections: []}` for an invalid/unknown `user_id` rather
  than an error, since the controller is responsible for 404ing when the
  user itself doesn't exist.
  """
  def get_graph(user_id) do
    case Ecto.UUID.cast(user_id) do
      {:ok, uuid} ->
        posts =
          Post
          |> where([p], p.user_id == ^uuid)
          |> order_by(desc: :inserted_at)
          |> Repo.all()
          |> Repo.preload(@post_preloads)

        post_ids = Enum.map(posts, & &1.id)

        connections =
          Connection
          |> where([c], c.post_id in ^post_ids and c.related_post_id in ^post_ids)
          |> Repo.all()

        %{posts: posts, connections: connections}

      :error ->
        %{posts: [], connections: []}
    end
  end
end
