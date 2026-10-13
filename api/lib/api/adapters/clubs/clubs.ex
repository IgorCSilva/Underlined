defmodule Api.Adapters.Clubs do
  @moduledoc """
  Facade over the book-club usecases: create, join/leave, and list/inspect
  clubs and their members.

  Callers build the DTO the target usecase expects and pass it in; this
  module only routes each DTO to its usecase.
  """

  alias Api.Usecases.Club.CreateClub.CreateClubUsecase
  alias Api.Usecases.Club.CreateClubChapter.CreateClubChapterUsecase
  alias Api.Usecases.Club.CreateClubComment.CreateClubCommentUsecase
  alias Api.Usecases.Club.CreateClubPost.CreateClubPostUsecase
  alias Api.Usecases.Club.GetClub.GetClubUsecase
  alias Api.Usecases.Club.JoinClub.JoinClubUsecase
  alias Api.Usecases.Club.LeaveClub.LeaveClubUsecase
  alias Api.Usecases.Club.ListClubChapters.ListClubChaptersUsecase
  alias Api.Usecases.Club.ListClubComments.ListClubCommentsUsecase
  alias Api.Usecases.Club.ListClubMembers.ListClubMembersUsecase
  alias Api.Usecases.Club.ListClubPosts.ListClubPostsUsecase
  alias Api.Usecases.Club.ListClubs.ListClubsUsecase
  alias Api.Usecases.Club.ListClubsForBook.ListClubsForBookUsecase
  alias Api.Usecases.Club.SetCurrentClubChapter.SetCurrentClubChapterUsecase
  alias Api.Usecases.Club.UpdateClubComment.UpdateClubCommentUsecase

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

  def list_clubs(dto) do
    ListClubsUsecase.call(dto, %ListClubsUsecase{repository: club_repository()})
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

  def create_club_chapter(dto) do
    CreateClubChapterUsecase.call(dto, %CreateClubChapterUsecase{
      repository: club_chapter_repository()
    })
  end

  def list_club_chapters(dto) do
    ListClubChaptersUsecase.call(dto, %ListClubChaptersUsecase{
      repository: club_chapter_repository()
    })
  end

  def set_current_club_chapter(dto) do
    SetCurrentClubChapterUsecase.call(dto, %SetCurrentClubChapterUsecase{
      repository: club_chapter_repository()
    })
  end

  def create_club_post(dto) do
    CreateClubPostUsecase.call(dto, %CreateClubPostUsecase{repository: club_post_repository()})
  end

  def list_club_posts(dto) do
    ListClubPostsUsecase.call(dto, %ListClubPostsUsecase{repository: club_post_repository()})
  end

  def create_club_comment(dto) do
    CreateClubCommentUsecase.call(dto, %CreateClubCommentUsecase{
      repository: club_comment_repository()
    })
  end

  def list_club_comments(dto) do
    ListClubCommentsUsecase.call(dto, %ListClubCommentsUsecase{
      repository: club_comment_repository()
    })
  end

  def update_club_comment(dto) do
    UpdateClubCommentUsecase.call(dto, %UpdateClubCommentUsecase{
      repository: club_comment_repository()
    })
  end

  defp club_repository, do: Application.get_env(:api, :club_repository) |> Map.new()

  defp club_chapter_repository,
    do: Application.get_env(:api, :club_chapter_repository) |> Map.new()

  defp club_post_repository, do: Application.get_env(:api, :club_post_repository) |> Map.new()

  defp club_comment_repository,
    do: Application.get_env(:api, :club_comment_repository) |> Map.new()

  defp community_health_enqueuer,
    do:
      Application.get_env(
        :api,
        :community_health_enqueuer,
        &Api.Infrastructure.Health.HealthyCommunity.CommunityHealthWorker.enqueue/1
      )
end
