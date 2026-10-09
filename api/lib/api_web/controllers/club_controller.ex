defmodule ApiWeb.ClubController do
  use ApiWeb, :controller

  alias Api.Adapters.Clubs
  alias Api.Usecases.Club.CreateClub.CreateClubUsecaseDto
  alias Api.Usecases.Club.GetClub.GetClubUsecaseDto
  alias Api.Usecases.Club.JoinClub.JoinClubUsecaseDto
  alias Api.Usecases.Club.LeaveClub.LeaveClubUsecaseDto
  alias Api.Usecases.Club.ListClubMembers.ListClubMembersUsecaseDto
  alias Api.Usecases.Club.ListClubsForBook.ListClubsForBookUsecaseDto

  action_fallback ApiWeb.FallbackController

  def index(conn, %{"book_id" => book_id}) do
    clubs =
      Clubs.list_clubs_for_book(%ListClubsForBookUsecaseDto{
        book_id: book_id,
        current_user: current_user(conn)
      })

    render(conn, :index, clubs: clubs)
  end

  def show(conn, %{"id" => id}) do
    with {:ok, club} <-
           Clubs.get_club(%GetClubUsecaseDto{id: id, current_user: current_user(conn)}) do
      render(conn, :show, club: club)
    end
  end

  def members(conn, %{"id" => id}) do
    with {:ok, members} <- Clubs.list_club_members(%ListClubMembersUsecaseDto{club_id: id}) do
      render(conn, :members, members: members)
    end
  end

  def create(conn, %{"book_id" => book_id, "club" => club_params}) do
    with {:ok, club} <-
           Clubs.create_club(%CreateClubUsecaseDto{
             creator: current_user(conn),
             attrs: Map.put(club_params, "book_id", book_id)
           }) do
      conn
      |> put_status(:created)
      |> render(:show, club: club)
    end
  end

  def join(conn, %{"id" => id}) do
    with {:ok, result} <-
           Clubs.join_club(%JoinClubUsecaseDto{user: current_user(conn), club_id: id}) do
      render(conn, :membership, result: result)
    end
  end

  def leave(conn, %{"id" => id}) do
    with {:ok, result} <-
           Clubs.leave_club(%LeaveClubUsecaseDto{user: current_user(conn), club_id: id}) do
      render(conn, :membership, result: result)
    end
  end

  defp current_user(conn), do: Api.Infrastructure.Guardian.Plug.current_resource(conn)
end
