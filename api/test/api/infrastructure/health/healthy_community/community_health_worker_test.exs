defmodule Api.Infrastructure.Health.HealthyCommunity.CommunityHealthWorkerTest do
  use ExUnit.Case, async: true

  import Mox

  alias Api.Infrastructure.Health.HealthyCommunity.CommunityHealthWorker

  setup :verify_on_exit!

  test "calls the configured CommunityHealthPort adapter with the job args" do
    Api.CommunityHealthMock
    |> expect(:ensure_member, fn %{actor_id: "user-1", community_id: "default"} ->
      {:ok, :synced}
    end)

    job = %Oban.Job{
      args: %{"action" => "ensure_member", "actor_id" => "user-1", "community_id" => "default"}
    }

    assert :ok = CommunityHealthWorker.perform(job)
  end

  test "surfaces an error so Oban retries" do
    Api.CommunityHealthMock
    |> expect(:ensure_member, fn _params -> {:error, :unavailable} end)

    job = %Oban.Job{
      args: %{"action" => "ensure_member", "actor_id" => "user-2", "community_id" => "default"}
    }

    assert {:error, :unavailable} = CommunityHealthWorker.perform(job)
  end
end
