defmodule Api.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      ApiWeb.Telemetry,
      # Start the Ecto repository
      Api.Repo,
      # Start the comment-creation rate limiter
      Api.Infrastructure.CommentRateLimiter,
      # Start the PubSub system
      {Phoenix.PubSub, name: Api.PubSub},
      # Start Finch
      {Finch, name: Api.Finch},
      # Tracks consecutive Community Health call failures so a down/slow CH
      # service can't pile up latency on Underlined's own requests
      Api.Infrastructure.Health.HealthyCommunity.CommunityHealthCircuitBreaker,
      # Runs background jobs (e.g. Community Health sync) off the request path
      {Oban, Application.fetch_env!(:api, Oban)},
      # In-memory cache for the keyword page's stats/related-keywords lookup
      {Cachex, name: :keyword_page_cache},
      # Start the Endpoint (http/https)
      ApiWeb.Endpoint
      # Start a worker by calling: Api.Worker.start_link(arg)
      # {Api.Worker, arg}
    ]

    attach_community_health_telemetry()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Api.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # A CommunityHealthWorker job that's exhausted every retry is a CH
  # incident to investigate, not something worth retrying forever — this
  # logs that case once, when Oban gives up on it.
  defp attach_community_health_telemetry do
    :telemetry.attach(
      "community-health-worker-discarded",
      [:oban, :job, :stop],
      &__MODULE__.handle_oban_job_stop/4,
      nil
    )
  end

  def handle_oban_job_stop(_event, _measurements, meta, _config) do
    if meta.job.worker == "Api.Infrastructure.Health.HealthyCommunity.CommunityHealthWorker" and
         meta.state == :discard do
      Logger.error(
        "CommunityHealthWorker discarded after #{meta.job.attempt} attempts: " <>
          inspect(meta.job.args)
      )
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
