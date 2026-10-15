defmodule Api.Adapters.Clubs do
  @moduledoc """
  Facade over the book-club usecases: create, join/leave, and list/inspect
  clubs and their members.

  Callers build the DTO the target usecase expects and pass it in; this
  module only routes each DTO to its usecase.
  """

  alias Api.Usecases.Club.CreateClub.CreateClubUsecase
  alias Api.Usecases.Club.GetClub.GetClubUsecase
  alias Api.Usecases.Club.JoinClub.JoinClubUsecase
  alias Api.Usecases.Club.LeaveClub.LeaveClubUsecase
  alias Api.Usecases.Club.ListClubMembers.ListClubMembersUsecase
  alias Api.Usecases.Club.ListClubsForBook.ListClubsForBookUsecase

  def create_club(dto) do
    CreateClubUsecase.call(dto, %CreateClubUsecase{
      repository: club_repository(),
      community_health_enqueuer: community_health_enqueuer()
    })
  end

  def get_club(dto), do: GetClubUsecase.call(dto, %GetClubUsecase{repository: club_repository()})

  def list_clubs_for_book(dto) do
    ListClubsForBookUsecase.call(dto, %ListClubsForBookUsecase{repository: club_repository()})
  end

  def join_club(dto) do
    JoinClubUsecase.call(dto, %JoinClubUsecase{
      repository: club_repository(),
      community_health_enqueuer: community_health_enqueuer()
    })
  end

  def leave_club(dto) do
    LeaveClubUsecase.call(dto, %LeaveClubUsecase{repository: club_repository()})
  end

  def list_club_members(dto) do
    ListClubMembersUsecase.call(dto, %ListClubMembersUsecase{repository: club_repository()})
  end

  defp club_repository, do: Application.get_env(:api, :club_repository) |> Map.new()

  defp community_health_enqueuer,
    do:
      Application.get_env(
        :api,
        :community_health_enqueuer,
        &Api.Infrastructure.Health.HealthyCommunity.CommunityHealthWorker.enqueue/1
      )
end
