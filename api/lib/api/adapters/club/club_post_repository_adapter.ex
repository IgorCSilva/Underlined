defmodule Api.Adapters.Club.ClubPostRepositoryAdapter do
  @moduledoc """
  Adapts a club-post repository (the adaptee) to the domain: calls it for
  the database entity/entities, then converts the result(s) into the pure
  Api.Domain.ClubPost business entity.
  """

  alias Api.Adapters.Club.ClubChapterRepositoryAdapter
  alias Api.Adapters.User.UserRepositoryAdapter
  alias Api.Domain.ClubPost, as: DomainClubPost

  def create_post(user, club_id, attrs, adaptee) do
    case adaptee.create_post(user, club_id, attrs) do
      {:ok, db_post} -> {:ok, to_domain(db_post)}
      {:error, reason} -> {:error, reason}
    end
  end

  def list_posts(club_id, viewer, adaptee) do
    case adaptee.list_posts(club_id, viewer) do
      {:ok, db_posts} -> {:ok, Enum.map(db_posts, &to_domain/1)}
      {:error, reason} -> {:error, reason}
    end
  end

  def get_post(id, adaptee) do
    case adaptee.get_post(id) do
      {:ok, db_post} -> {:ok, to_domain(db_post)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "Converts a Postgres club-post entity (with :user/:chapter preloaded) into the pure domain entity."
  def to_domain(db_post) do
    %DomainClubPost{
      id: db_post.id,
      body: db_post.body,
      chapter: chapter_to_domain(db_post.chapter),
      user: UserRepositoryAdapter.to_domain(db_post.user),
      comment_count: db_post.comment_count,
      spoiler_blocked: db_post.spoiler_blocked,
      inserted_at: db_post.inserted_at,
      updated_at: db_post.updated_at
    }
  end

  defp chapter_to_domain(nil), do: nil
  defp chapter_to_domain(db_chapter), do: ClubChapterRepositoryAdapter.to_domain(db_chapter)
end
