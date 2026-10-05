defmodule Api.Adapters.CommunityHealthPort do
  @moduledoc """
  Behaviour for the Community Health integration (see
  docs/base_content/healthy_community/roadmap.md in the HealthyCommunity
  repo for the resilience contract this follows). Underlined never talks to
  the CH HTTP API directly — usecases only ever call through this port, via
  `Application.get_env(:api, :community_health, Api.Infrastructure.Health.HealthyCommunity.CommunityHealthNoop)`,
  exactly like `Api.Adapters.MailerPort`.
  """

  @callback ensure_member(%{actor_id: String.t(), community_id: String.t()}) ::
              {:ok, term()} | {:error, term()}

  @callback record_action(%{
              required(:actor_id) => String.t(),
              required(:action_type) => String.t(),
              required(:resource_type) => String.t(),
              required(:resource_id) => String.t(),
              required(:community_id) => String.t(),
              required(:event_key) => String.t(),
              optional(:context) => map()
            }) :: {:ok, term()} | {:error, term()}

  @callback submit_report(%{
              reporter_id: String.t(),
              resource_type: String.t(),
              resource_id: String.t(),
              community_id: String.t(),
              reason: String.t(),
              description: String.t() | nil
            }) :: {:ok, term()} | {:error, term()}

  @callback list_rules(String.t()) :: {:ok, [map()]} | {:error, term()}
end
