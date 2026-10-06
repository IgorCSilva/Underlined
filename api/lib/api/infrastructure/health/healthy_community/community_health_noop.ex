defmodule Api.Infrastructure.Health.HealthyCommunity.CommunityHealthNoop do
  @moduledoc """
  Default CommunityHealthPort adapter: zero I/O, always succeeds. This is
  what runs whenever the integration is disabled or unconfigured, so a
  missing env var fails closed rather than open (see
  Api.Adapters.CommunityHealthPort).
  """

  @behaviour Api.Adapters.CommunityHealthPort

  @impl true
  def ensure_member(_params), do: {:ok, :skipped}

  @impl true
  def record_action(_params), do: {:ok, :skipped}

  @impl true
  def submit_report(_params), do: {:ok, :skipped}

  @impl true
  def list_rules(_community_id), do: {:error, :unavailable}

  @impl true
  def get_reputation(_params), do: {:error, :unavailable}

  @impl true
  def get_trust_level(_params), do: {:error, :unavailable}
end
