defmodule ApiWeb.ClubChapterController do
  use ApiWeb, :controller

  alias Api.Adapters.Clubs
  alias Api.Usecases.Club.CreateClubChapter.CreateClubChapterUsecaseDto
  alias Api.Usecases.Club.ListClubChapters.ListClubChaptersUsecaseDto
  alias Api.Usecases.Club.SetCurrentClubChapter.SetCurrentClubChapterUsecaseDto

  action_fallback ApiWeb.FallbackController

  def index(conn, %{"club_id" => club_id}) do
    with {:ok, chapters} <-
           Clubs.list_club_chapters(%ListClubChaptersUsecaseDto{club_id: club_id}) do
      render(conn, :index, chapters: chapters)
    end
  end

  def create(conn, %{"club_id" => club_id, "chapter" => chapter_params}) do
    with {:ok, chapter} <-
           Clubs.create_club_chapter(%CreateClubChapterUsecaseDto{
             user: current_user(conn),
             club_id: club_id,
             attrs: chapter_params
           }) do
      conn
      |> put_status(:created)
      |> render(:show, chapter: chapter)
    end
  end

  def set_current(conn, %{"club_id" => club_id, "id" => chapter_id}) do
    with {:ok, chapter} <-
           Clubs.set_current_club_chapter(%SetCurrentClubChapterUsecaseDto{
             user: current_user(conn),
             club_id: club_id,
             chapter_id: chapter_id
           }) do
      render(conn, :show, chapter: chapter)
    end
  end

  defp current_user(conn), do: Api.Infrastructure.Guardian.Plug.current_resource(conn)
end
