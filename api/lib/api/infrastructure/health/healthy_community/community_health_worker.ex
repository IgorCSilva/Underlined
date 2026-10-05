defmodule Api.Infrastructure.Health.HealthyCommunity.CommunityHealthWorker do
  @moduledoc """
  Fire-and-forget bridge from usecases to the CommunityHealthPort. Keeps
  Community Health entirely off the request path: a usecase enqueues this
  job after its own commit, and only this worker calls
  `community_health().ensure_member/1`. Retries with backoff; once Oban's
  attempt budget is exhausted the job is discarded (logged in
  Api.Application) rather than retried forever.
  """

  use Oban.Worker, queue: :community_health, max_attempts: 8

  alias Api.Infrastructure.Health.HealthyCommunity.CommunityHealthNoop

  @doc """
  Enqueues a job for this worker. This is the one function usecases are
  handed (injected via their struct, resolved by the calling facade from
  `Application.get_env`) — they call it without ever aliasing this module,
  Oban, or knowing a job/queue is involved at all.
  """
  def enqueue(args), do: args |> new() |> Oban.insert()

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"action" => "ensure_member", "actor_id" => actor_id, "community_id" => community_id}
      }) do
    case community_health().ensure_member(%{actor_id: actor_id, community_id: community_id}) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  def perform(%Oban.Job{
        args: %{
          "action" => "record_action",
          "actor_id" => actor_id,
          "action_type" => action_type,
          "resource_type" => resource_type,
          "resource_id" => resource_id,
          "community_id" => community_id,
          "event_key" => event_key
        }
      }) do
    params = %{
      actor_id: actor_id,
      action_type: action_type,
      resource_type: resource_type,
      resource_id: resource_id,
      community_id: community_id,
      event_key: event_key
    }

    case community_health().record_action(params) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  def perform(%Oban.Job{
        args: %{
          "action" => "submit_report",
          "reporter_id" => reporter_id,
          "resource_type" => resource_type,
          "resource_id" => resource_id,
          "community_id" => community_id,
          "reason" => reason
        } = args
      }) do
    params = %{
      reporter_id: reporter_id,
      resource_type: resource_type,
      resource_id: resource_id,
      community_id: community_id,
      reason: reason,
      description: Map.get(args, "description")
    }

    case community_health().submit_report(params) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp community_health, do: Application.get_env(:api, :community_health, CommunityHealthNoop)
end
