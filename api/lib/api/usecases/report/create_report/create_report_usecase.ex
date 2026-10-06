defmodule Api.Usecases.Report.CreateReport.CreateReportUsecase do
  @moduledoc """
  Flags a resource (a post or a comment) as violating one of its
  community's rules. Underlined keeps no local copy of reports —
  moderation is Community Health's domain — so this usecase only
  validates input and enqueues the sync job; the caller injects
  `community_health_enqueuer`, exactly like `CreatePostUsecase`.
  """

  alias Api.Usecases.Report.CreateReport.CreateReportUsecaseDto

  defstruct [:community_health_enqueuer]

  @resource_types ~w(post comment)
  @types %{resource_type: :string, resource_id: :string, reason: :string, description: :string}

  def call(%CreateReportUsecaseDto{user: user, attrs: attrs}, %__MODULE__{
        community_health_enqueuer: enqueue_community_health
      }) do
    changeset = changeset(attrs)

    if changeset.valid? do
      report = Ecto.Changeset.apply_changes(changeset)

      enqueue_community_health.(%{
        action: "submit_report",
        reporter_id: user.id,
        resource_type: report.resource_type,
        resource_id: report.resource_id,
        community_id: default_community_id(),
        reason: report.reason,
        description: report.description
      })

      {:ok, :queued}
    else
      {:error, %{changeset | action: :insert}}
    end
  end

  defp changeset(attrs) do
    {%{}, @types}
    |> Ecto.Changeset.cast(attrs, Map.keys(@types))
    |> Ecto.Changeset.validate_required([:resource_type, :resource_id, :reason])
    |> Ecto.Changeset.validate_inclusion(:resource_type, @resource_types)
  end

  defp default_community_id,
    do: Application.get_env(:api, :community_health_default_community, "default")
end
