defmodule Api.Usecases.User.GetCommunityHealth.GetCommunityHealthUsecase do
  @moduledoc """
  Reads a user's reputation/trust level from Community Health for the
  profile page's contribution section (Step 12). Like
  `ListReportReasonsUsecase`, this is a synchronous read with a safe
  fallback — never a hot path, only called from the endpoint that
  explicitly shows this data. The caller injects
  `community_health_reputation_reader` and `community_health_trust_reader`,
  1-arg functions resolved from `Application.get_env` exactly like
  `community_health_enqueuer`.
  """

  alias Api.Usecases.User.GetCommunityHealth.GetCommunityHealthUsecaseDto

  defstruct [:community_health_reputation_reader, :community_health_trust_reader]

  def call(%GetCommunityHealthUsecaseDto{user_id: user_id}, %__MODULE__{
        community_health_reputation_reader: get_reputation,
        community_health_trust_reader: get_trust_level
      }) do
    params = %{actor_id: user_id, community_id: default_community_id()}

    case {get_reputation.(params), get_trust_level.(params)} do
      {{:ok, %{level: level}}, {:ok, %{trust_level: trust_level}}} ->
        {:ok, %{reputation_level: level, trust_level: trust_level, community_health_available: true}}

      _ ->
        {:ok, %{reputation_level: nil, trust_level: nil, community_health_available: false}}
    end
  end

  defp default_community_id,
    do: Application.get_env(:api, :community_health_default_community, "default")
end
