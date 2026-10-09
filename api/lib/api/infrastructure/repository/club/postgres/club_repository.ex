defmodule Api.Infrastructure.Repository.Club.Postgres.ClubRepository do
  @moduledoc """
  Postgres-backed data access for the book-club entity.
  """

  import Ecto.Query, warn: false

  alias Api.Infrastructure.Repository.Book.Postgres.Book
  alias Api.Infrastructure.Repository.Club.Postgres.{Club, ClubMembership}
  alias Api.Infrastructure.Repository.User.Postgres.User
  alias Api.Repo

  @preview_limit 4

  @doc """
  Creates a club scoped to `attrs["book_id"]` and makes `creator` its first
  member, in one transaction — a club is never left without at least one
  member.
  """
  def create_club(creator, attrs) do
    with %Book{} <- Repo.get(Book, attrs["book_id"]) || {:error, :not_found} do
      multi =
        Ecto.Multi.new()
        |> Ecto.Multi.insert(
          :club,
          Club.changeset(%Club{}, %{
            "name" => attrs["name"],
            "description" => attrs["description"],
            "book_id" => attrs["book_id"],
            "creator_id" => creator.id
          })
        )
        |> Ecto.Multi.insert(:membership, fn %{club: club} ->
          ClubMembership.changeset(%ClubMembership{}, %{
            "club_id" => club.id,
            "user_id" => creator.id
          })
        end)

      case Repo.transaction(multi) do
        {:ok, %{club: club}} ->
          {:ok, club |> Repo.preload([:book, :creator]) |> annotate(creator)}

        {:error, _op, changeset, _changes} ->
          {:error, changeset}
      end
    end
  end

  @doc "Looks up a club by id, annotated for `current_user`. `{:error, :not_found}` when missing."
  def get_club(id, current_user) do
    case Repo.get(Club, id) do
      nil -> {:error, :not_found}
      club -> {:ok, club |> Repo.preload([:book, :creator]) |> annotate(current_user)}
    end
  end

  @doc "Lists every club scoped to `book_id`, newest first, annotated for `current_user`."
  def list_clubs_for_book(book_id, current_user) do
    Club
    |> where([c], c.book_id == ^book_id)
    |> order_by([c], desc: c.inserted_at)
    |> Repo.all()
    |> Repo.preload([:book, :creator])
    |> Enum.map(&annotate(&1, current_user))
  end

  @doc """
  Joins `user` to `club_id`. Idempotent: joining an already-joined club
  just returns the current membership state.
  """
  def join_club(user, club_id) do
    with %Club{} <- Repo.get(Club, club_id) || {:error, :not_found} do
      case Repo.get_by(ClubMembership, club_id: club_id, user_id: user.id) do
        nil ->
          attrs = %{"club_id" => club_id, "user_id" => user.id}

          case %ClubMembership{} |> ClubMembership.changeset(attrs) |> Repo.insert() do
            {:ok, _membership} -> {:ok, %{joined: true}}
            {:error, changeset} -> {:error, changeset}
          end

        _membership ->
          {:ok, %{joined: true}}
      end
    end
  end

  @doc """
  Leaves `club_id` on behalf of `user`. Idempotent: leaving a club the user
  isn't a member of is a no-op that returns the current state.
  """
  def leave_club(user, club_id) do
    case Repo.get_by(ClubMembership, club_id: club_id, user_id: user.id) do
      nil ->
        {:ok, %{joined: false}}

      membership ->
        Repo.delete!(membership)
        {:ok, %{joined: false}}
    end
  end

  @doc "Lists every member of `club_id`, earliest joiner first."
  def list_members(club_id) do
    with %Club{} <- Repo.get(Club, club_id) || {:error, :not_found} do
      members =
        from(m in ClubMembership,
          join: u in User,
          on: u.id == m.user_id,
          where: m.club_id == ^club_id,
          order_by: [asc: m.inserted_at],
          select: u
        )
        |> Repo.all()

      {:ok, members}
    end
  end

  defp annotate(club, current_user) do
    member_count = Repo.aggregate(from(m in ClubMembership, where: m.club_id == ^club.id), :count)

    preview =
      from(m in ClubMembership,
        join: u in User,
        on: u.id == m.user_id,
        where: m.club_id == ^club.id,
        order_by: [asc: m.inserted_at],
        limit: ^@preview_limit,
        select: u
      )
      |> Repo.all()

    %{
      club
      | member_count: member_count,
        members_preview: preview,
        joined_by_user: joined?(club.id, current_user)
    }
  end

  defp joined?(_club_id, nil), do: false

  defp joined?(club_id, current_user) do
    Repo.exists?(
      from m in ClubMembership, where: m.club_id == ^club_id and m.user_id == ^current_user.id
    )
  end
end
