defmodule Mix.Tasks.CommunityHealth.BackfillMembers do
  use Mix.Task

  import Ecto.Query

  alias Api.Infrastructure.Health.HealthyCommunity.CommunityHealthWorker
  alias Api.Infrastructure.Repository.User.Postgres.User
  alias Api.Repo

  @shortdoc "Enqueues a Community Health ensure_member job for every existing user"

  @moduledoc """
  One-time backfill for users created before this integration shipped — new
  users are covered going forward by RegisterUserUsecase/UpdateProfileUsecase
  themselves.

      mix community_health.backfill_members
  """

  def run(_args) do
    Mix.Task.run("app.start")

    community_id = Application.get_env(:api, :community_health_default_community, "default")

    count =
      User
      |> select([u], u.id)
      |> Repo.all()
      |> Enum.reduce(0, fn user_id, count ->
        {:ok, _job} =
          %{action: "ensure_member", actor_id: user_id, community_id: community_id}
          |> CommunityHealthWorker.new()
          |> Oban.insert()

        count + 1
      end)

    Mix.shell().info("Enqueued Community Health ensure_member jobs for #{count} existing users.")
  end
end
