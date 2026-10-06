defmodule Api.Usecases.User.UpdateProfile.UpdateProfileUsecase do
  @moduledoc """
  Updates a user's profile fields (name, bio, avatar_url).

  The Community Health sync is injected as a `community_health_enqueuer`
  function — this usecase never aliases `CommunityHealthWorker` or `Oban`
  directly.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User
  alias Api.Repo
  alias Api.Usecases.User.UpdateProfile.UpdateProfileUsecaseDto

  defstruct [:community_health_enqueuer]

  def call(%UpdateProfileUsecaseDto{user: %User{} = user, attrs: attrs}, %__MODULE__{
        community_health_enqueuer: enqueue_community_health
      }) do
    with {:ok, updated_user} <- user |> User.profile_changeset(attrs) |> Repo.update() do
      # ensure_member is idempotent on the CH side, so re-syncing on every
      # profile edit (not just name changes) is cheap and keeps CH's
      # mirrored display identity current for audit-log readability.
      enqueue_community_health.(%{
        action: "ensure_member",
        actor_id: updated_user.id,
        community_id: default_community_id()
      })

      {:ok, updated_user}
    end
  end

  defp default_community_id,
    do: Application.get_env(:api, :community_health_default_community, "default")
end
