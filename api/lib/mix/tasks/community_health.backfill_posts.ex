defmodule Mix.Tasks.CommunityHealth.BackfillPosts do
  use Mix.Task

  import Ecto.Query

  alias Api.Infrastructure.Health.HealthyCommunity.CommunityHealthWorker
  alias Api.Infrastructure.Repository.Post.Postgres.Post
  alias Api.Repo

  @shortdoc "Enqueues a Community Health CREATE action job for every existing post"

  @moduledoc """
  One-time backfill for posts published before this integration shipped —
  new posts are covered going forward by CreatePostUsecase itself. Safe to
  re-run: each job's event_key ("post:create:<id>") is idempotent on CH's
  side, so an already-recorded post is just acknowledged again, never
  double-counted.

      mix community_health.backfill_posts
  """

  def run(_args) do
    Mix.Task.run("app.start")

    community_id = Application.get_env(:api, :community_health_default_community, "default")

    count =
      Post
      |> select([p], {p.id, p.user_id})
      |> Repo.all()
      |> Enum.reduce(0, fn {post_id, user_id}, count ->
        {:ok, _job} =
          %{
            action: "record_action",
            actor_id: user_id,
            action_type: "CREATE",
            resource_type: "post",
            resource_id: post_id,
            community_id: community_id,
            event_key: "post:create:#{post_id}"
          }
          |> CommunityHealthWorker.new()
          |> Oban.insert()

        count + 1
      end)

    Mix.shell().info("Enqueued Community Health CREATE action jobs for #{count} existing posts.")
  end
end
