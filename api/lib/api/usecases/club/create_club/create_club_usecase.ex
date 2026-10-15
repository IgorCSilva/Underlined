defmodule Api.Usecases.Club.CreateClub.CreateClubUsecase do
  @moduledoc """
  Creates a book club scoped to a book, with its creator as the first
  member.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}` and a
  `community_health_enqueuer` function used to register the club as its
  own Community Health community — this usecase never aliases an
  Infrastructure module directly.
  """

  alias Api.Usecases.Club.CreateClub.CreateClubUsecaseDto

  defstruct [:repository, :community_health_enqueuer]

  def call(%CreateClubUsecaseDto{creator: creator, attrs: attrs}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee},
        community_health_enqueuer: enqueue_community_health
      }) do
    with {:ok, club} <- adapter.create_club(creator, attrs, adaptee) do
      # `ensure_member` already registers the community on first sight (see
      # CommunityHealthClient.ensure_member/1), so one call both creates the
      # club's own CH community and enrolls its creator — no separate
      # "register community" step needed.
      enqueue_community_health.(%{
        action: "ensure_member",
        actor_id: creator.id,
        community_id: club_community_id(club.id)
      })

      {:ok, club}
    end
  end

  defp club_community_id(club_id), do: "club_#{club_id}"
end
