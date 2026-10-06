defmodule Api.Infrastructure.Health.HealthyCommunity.CommunityHealthCircuitBreaker do
  @moduledoc """
  ETS-backed circuit breaker guarding
  Api.Infrastructure.Health.HealthyCommunity.CommunityHealthClient calls, so
  a down/slow Community Health service can't pile up slow timeouts
  on every Underlined request that happens to touch it. Trips open after
  `@max_failures` consecutive failures and stays open for `@cooldown_ms`
  before letting another attempt through.
  """

  use GenServer

  @table __MODULE__
  @max_failures 5
  @cooldown_ms 30_000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    :ets.new(@table, [:named_table, :public, :set, read_concurrency: true])
    :ets.insert(@table, {:failures, 0})
    :ets.insert(@table, {:opened_at, nil})
    {:ok, %{}}
  end

  @doc "True when the circuit is open and calls should be skipped."
  def open? do
    case :ets.lookup(@table, :opened_at) do
      [{:opened_at, nil}] -> false
      [{:opened_at, opened_at}] -> System.monotonic_time(:millisecond) - opened_at < @cooldown_ms
      [] -> false
    end
  end

  def record_success do
    :ets.insert(@table, {:failures, 0})
    :ets.insert(@table, {:opened_at, nil})
    :ok
  end

  def record_failure do
    failures = :ets.update_counter(@table, :failures, {2, 1}, {:failures, 0})

    if failures >= @max_failures do
      :ets.insert(@table, {:opened_at, System.monotonic_time(:millisecond)})
    end

    :ok
  end
end
