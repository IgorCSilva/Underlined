defmodule Api.Usecases.User.RegisterUser.RegisterUserUsecase do
  @moduledoc """
  Creates a new user from registration attributes.

  The Community Health sync is injected as a `community_health_enqueuer`
  function — this usecase never aliases `CommunityHealthWorker` or `Oban`
  directly.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User
  alias Api.Repo
  alias Api.Usecases.User.RegisterUser.RegisterUserUsecaseDto

  defstruct [:community_health_enqueuer]

  def call(%RegisterUserUsecaseDto{attrs: attrs}, %__MODULE__{
        community_health_enqueuer: enqueue_community_health
      }) do
    with {:ok, user} <- %User{} |> User.registration_changeset(attrs) |> Repo.insert() do
      # Fire-and-forget — the account exists as a Community Health
      # actor/member from the moment it's created, with no change to the
      # signup flow itself.
      enqueue_community_health.(%{
        action: "ensure_member",
        actor_id: user.id,
        community_id: default_community_id()
      })

      {:ok, user}
    end
  end

  defp default_community_id,
    do: Application.get_env(:api, :community_health_default_community, "default")
end
