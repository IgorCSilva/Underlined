defmodule Api.Infrastructure.Health.HealthyCommunity.CommunityHealthClient do
  @moduledoc """
  CommunityHealthPort implementation backed by HTTP calls to the standalone
  Community Health API (see openapi.yaml in the HealthyCommunity repo for
  the contract). Only ever called from
  Api.Infrastructure.Health.HealthyCommunity.CommunityHealthWorker, never
  in-request — Finch is already a dependency, no new HTTP client needed.
  Every call is wrapped with a strict timeout and the shared circuit
  breaker, so a slow/down CH service can never pile up latency here.
  """

  @behaviour Api.Adapters.CommunityHealthPort

  alias Api.Infrastructure.Health.HealthyCommunity.CommunityHealthCircuitBreaker, as: CircuitBreaker

  @write_timeout 2_000
  @read_timeout 300

  @impl true
  def ensure_member(%{actor_id: actor_id, community_id: community_ref}) do
    if CircuitBreaker.open?() do
      {:error, :unavailable}
    else
      with {:ok, _} <- ensure_community(community_ref),
           {:ok, _} <- ensure_membership(community_ref, actor_id) do
        CircuitBreaker.record_success()
        {:ok, :synced}
      else
        {:error, reason} ->
          CircuitBreaker.record_failure()
          {:error, reason}
      end
    end
  end

  @impl true
  def record_action(%{
        actor_id: actor_id,
        action_type: action_type,
        resource_type: resource_type,
        resource_id: resource_id,
        community_id: community_ref,
        event_key: event_key
      } = params) do
    context = Map.get(params, :context, %{})

    if CircuitBreaker.open?() do
      {:error, :unavailable}
    else
      with {:ok, _} <- ensure_community(community_ref),
           {:ok, _} <-
             submit_event(
               community_ref,
               actor_id,
               action_type,
               resource_type,
               resource_id,
               event_key,
               context
             ) do
        CircuitBreaker.record_success()
        {:ok, :recorded}
      else
        {:error, reason} ->
          CircuitBreaker.record_failure()
          {:error, reason}
      end
    end
  end

  @impl true
  def submit_report(%{
        reporter_id: reporter_id,
        resource_type: resource_type,
        resource_id: resource_id,
        community_id: community_ref,
        reason: reason,
        description: description
      }) do
    if CircuitBreaker.open?() do
      {:error, :unavailable}
    else
      with {:ok, _} <- ensure_community(community_ref),
           {:ok, _} <-
             post_report(community_ref, reporter_id, resource_type, resource_id, reason, description) do
        CircuitBreaker.record_success()
        {:ok, :recorded}
      else
        {:error, reason} ->
          CircuitBreaker.record_failure()
          {:error, reason}
      end
    end
  end

  @impl true
  def list_rules(community_ref) do
    if CircuitBreaker.open?() do
      {:error, :unavailable}
    else
      case request(:get, "/v1/communities/#{community_ref}/rules", nil, @read_timeout) do
        {:ok, body} ->
          CircuitBreaker.record_success()
          {:ok, decode_rules(body)}

        {:error, reason} ->
          CircuitBreaker.record_failure()
          {:error, reason}
      end
    end
  end

  @impl true
  def get_reputation(%{actor_id: actor_id, community_id: community_ref}) do
    if CircuitBreaker.open?() do
      {:error, :unavailable}
    else
      case request(:get, "/v1/communities/#{community_ref}/members/#{actor_id}/reputation", nil, @read_timeout) do
        {:ok, body} ->
          CircuitBreaker.record_success()
          decode_reputation(body)

        {:error, reason} ->
          CircuitBreaker.record_failure()
          {:error, reason}
      end
    end
  end

  @impl true
  def get_trust_level(%{actor_id: actor_id, community_id: community_ref}) do
    if CircuitBreaker.open?() do
      {:error, :unavailable}
    else
      case request(:get, "/v1/communities/#{community_ref}/members/#{actor_id}/trust", nil, @read_timeout) do
        {:ok, body} ->
          CircuitBreaker.record_success()
          decode_trust(body)

        {:error, reason} ->
          CircuitBreaker.record_failure()
          {:error, reason}
      end
    end
  end

  defp decode_reputation(body) do
    case Jason.decode(body) do
      {:ok, %{"score" => score, "level" => level}} -> {:ok, %{score: score, level: level}}
      _ -> {:error, :invalid_response}
    end
  end

  defp decode_trust(body) do
    case Jason.decode(body) do
      {:ok, %{"trust_level" => trust_level}} -> {:ok, %{trust_level: trust_level}}
      _ -> {:error, :invalid_response}
    end
  end

  defp ensure_community(community_ref) do
    name = community_ref |> String.replace("_", " ") |> String.capitalize()
    request(:post, "/v1/communities", %{external_ref: community_ref, name: name})
  end

  defp ensure_membership(community_ref, actor_id) do
    request(:put, "/v1/communities/#{community_ref}/members/#{actor_id}", nil)
  end

  defp submit_event(community_ref, actor_id, action_type, resource_type, resource_id, event_key, context) do
    request(:post, "/v1/events", %{
      community_ref: community_ref,
      actor_id: actor_id,
      action_type: action_type,
      resource_type: resource_type,
      resource_ref: resource_id,
      event_key: event_key,
      context: context
    })
  end

  defp post_report(community_ref, reporter_id, resource_type, resource_id, reason, description) do
    request(:post, "/v1/reports", %{
      community_ref: community_ref,
      reporter_id: reporter_id,
      resource_type: resource_type,
      resource_ref: resource_id,
      reason: reason,
      description: description
    })
  end

  defp decode_rules(body) do
    case Jason.decode(body) do
      {:ok, %{"data" => rules}} ->
        Enum.map(rules, fn rule ->
          %{
            code: rule["code"],
            name: rule["name"],
            description: rule["description"],
            severity: rule["severity"]
          }
        end)

      _ ->
        []
    end
  end

  defp request(method, path, body, timeout \\ @write_timeout) do
    config = Application.fetch_env!(:api, __MODULE__)

    request =
      Finch.build(
        method,
        config[:base_url] <> path,
        headers(config[:api_key]),
        body && Jason.encode!(body)
      )

    case Finch.request(request, Api.Finch, receive_timeout: timeout) do
      {:ok, %Finch.Response{status: status} = response} when status in 200..299 ->
        {:ok, response.body}

      {:ok, %Finch.Response{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp headers(api_key) do
    [
      {"authorization", "Bearer #{api_key}"},
      {"content-type", "application/json"}
    ]
  end
end
