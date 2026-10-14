defmodule ApiWeb.ClubReadingProgressController do
  use ApiWeb, :controller

  alias Api.Adapters.Clubs
  alias Api.Usecases.Club.GetClubReadingProgress.GetClubReadingProgressUsecaseDto
  alias Api.Usecases.Club.SetClubReadingProgress.SetClubReadingProgressUsecaseDto

  action_fallback ApiWeb.FallbackController

  def show(conn, %{"club_id" => club_id}) do
    with {:ok, progress} <-
           Clubs.get_club_reading_progress(%GetClubReadingProgressUsecaseDto{
             user: current_user(conn),
             club_id: club_id
           }) do
      render(conn, :show, progress: progress)
    end
  end

  def update(conn, %{"club_id" => club_id, "reading_progress" => attrs}) do
    with {:ok, progress} <-
           Clubs.set_club_reading_progress(%SetClubReadingProgressUsecaseDto{
             user: current_user(conn),
             club_id: club_id,
             chapter_id: attrs["chapter_id"]
           }) do
      render(conn, :show, progress: progress)
    end
  end

  defp current_user(conn), do: Api.Infrastructure.Guardian.Plug.current_resource(conn)
end
