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

  test "forwards a record_action job's context to the CommunityHealthPort adapter" do
    Api.CommunityHealthMock
    |> expect(:record_action, fn %{
                                    actor_id: "user-3",
                                    action_type: "COMMENT",
                                    resource_type: "comment",
                                    resource_id: "comment-1",
                                    community_id: "default",
                                    event_key: "comment:create:comment-1",
                                    context: %{"parent_type" => "reply"}
                                  } ->
      {:ok, :recorded}
    end)

    job = %Oban.Job{
      args: %{
        "action" => "record_action",
        "actor_id" => "user-3",
        "action_type" => "COMMENT",
        "resource_type" => "comment",
        "resource_id" => "comment-1",
        "community_id" => "default",
        "event_key" => "comment:create:comment-1",
        "context" => %{"parent_type" => "reply"}
      }
    }

    assert :ok = CommunityHealthWorker.perform(job)
  end

  test "defaults context to an empty map when the job args omit it" do
    Api.CommunityHealthMock
    |> expect(:record_action, fn %{context: %{}} -> {:ok, :recorded} end)

    job = %Oban.Job{
      args: %{
        "action" => "record_action",
        "actor_id" => "user-4",
        "action_type" => "REACT",
        "resource_type" => "post",
        "resource_id" => "post-1",
        "community_id" => "default",
        "event_key" => "post:react:user-4:post-1:1"
      }
    }

    assert :ok = CommunityHealthWorker.perform(job)
  end
end
