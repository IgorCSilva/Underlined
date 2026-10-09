defmodule Api.Adapters.Club.ClubRepositoryAdapter do
  @moduledoc """
  Adapts a club repository (the adaptee) to the domain: calls it for the
  database entity/entities, then converts the result(s) into the pure
  Api.Domain.Club business entity.
  """

  alias Api.Adapters.Book.BookRepositoryAdapter
  alias Api.Adapters.User.UserRepositoryAdapter
  alias Api.Domain.Club, as: DomainClub

  def create_club(creator, attrs, adaptee) do
    case adaptee.create_club(creator, attrs) do
      {:ok, db_club} -> {:ok, to_domain(db_club)}
      {:error, reason} -> {:error, reason}
    end
  end

  def get_club(id, current_user, adaptee) do
    case adaptee.get_club(id, current_user) do
      {:ok, db_club} -> {:ok, to_domain(db_club)}
      {:error, reason} -> {:error, reason}
    end
  end

  def list_clubs_for_book(book_id, current_user, adaptee) do
    adaptee.list_clubs_for_book(book_id, current_user) |> Enum.map(&to_domain/1)
  end

  def join_club(user, club_id, adaptee), do: adaptee.join_club(user, club_id)
  def leave_club(user, club_id, adaptee), do: adaptee.leave_club(user, club_id)

  def list_members(club_id, adaptee) do
    case adaptee.list_members(club_id) do
      {:ok, members} -> {:ok, Enum.map(members, &UserRepositoryAdapter.to_domain/1)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "Converts a Postgres club entity (with :book/:creator preloaded) into the pure domain entity."
  def to_domain(db_club) do
    %DomainClub{
      id: db_club.id,
      name: db_club.name,
      description: db_club.description,
      book: BookRepositoryAdapter.to_domain(db_club.book),
      creator: UserRepositoryAdapter.to_domain(db_club.creator),
      member_count: db_club.member_count,
      members_preview: Enum.map(db_club.members_preview, &UserRepositoryAdapter.to_domain/1),
      joined_by_user: db_club.joined_by_user,
      inserted_at: db_club.inserted_at,
      updated_at: db_club.updated_at
    }
  end
end
