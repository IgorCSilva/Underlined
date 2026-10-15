defmodule Api.Usecases.Club.JoinClub.JoinClubUsecase do
  @moduledoc """
  Joins a user to a club. Idempotent.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}` and a
  `community_health_enqueuer` function used to enroll the joiner in the
  club's own Community Health community — this usecase never aliases an
  Infrastructure module directly.
  """

  alias Api.Usecases.Club.JoinClub.JoinClubUsecaseDto

  defstruct [:repository, :community_health_enqueuer]

  def call(%JoinClubUsecaseDto{user: user, club_id: club_id}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee},
        community_health_enqueuer: enqueue_community_health
      }) do
    with {:ok, result} <- adapter.join_club(user, club_id, adaptee) do
      enqueue_community_health.(%{
        action: "ensure_member",
        actor_id: user.id,
        community_id: "club_#{club_id}"
      })

      {:ok, result}
    end
  end
end
