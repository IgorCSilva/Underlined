defmodule Api.Usecases.Report.ListReportReasons.ListReportReasonsUsecase do
  @moduledoc """
  Reads a community's active rules from Community Health to populate the
  reason codes a report modal offers. Unlike `CreateReportUsecase`, this is
  a synchronous read with a safe fallback — never a hot path, only called
  from the endpoint that explicitly shows this data (cross-cutting kill-
  switch contract in healthy_community/roadmap.md). The caller injects
  `community_health_reader`, a 1-arg function resolved from
  `Application.get_env` exactly like `community_health_enqueuer`.
  """

  alias Api.Usecases.Report.ListReportReasons.ListReportReasonsUsecaseDto

  defstruct [:community_health_reader]

  def call(%ListReportReasonsUsecaseDto{}, %__MODULE__{community_health_reader: list_rules}) do
    case list_rules.(default_community_id()) do
      {:ok, rules} -> {:ok, %{rules: rules, community_health_available: true}}
      {:error, _reason} -> {:ok, %{rules: [], community_health_available: false}}
    end
  end

  defp default_community_id,
    do: Application.get_env(:api, :community_health_default_community, "default")
end
