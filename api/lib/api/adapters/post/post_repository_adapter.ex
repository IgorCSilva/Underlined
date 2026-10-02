defmodule Api.Adapters.Post.PostRepositoryAdapter do
  @moduledoc """
  Adapts a post repository (the adaptee) to the domain: calls it for the
  database entity/entities, then converts the result(s) into the pure
  Api.Domain.Post business entity.
  """

  alias Api.Adapters.Book.BookRepositoryAdapter
  alias Api.Adapters.Keyword.KeywordRepositoryAdapter
  alias Api.Adapters.Passage.PassageRepositoryAdapter
  alias Api.Adapters.User.UserRepositoryAdapter
  alias Api.Domain.Post, as: DomainPost

  def create_post(user, attrs, adaptee) do
    case adaptee.create_post(user, attrs) do
      {:ok, db_post} -> {:ok, to_domain(db_post)}
      {:error, :not_found} -> {:error, :not_found}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def list_posts(before, current_user, adaptee) do
    adaptee.list_posts(before, current_user) |> Enum.map(&to_domain/1)
  end

  def list_following_posts(user, before, adaptee) do
    adaptee.list_following_posts(user, before) |> Enum.map(&to_domain/1)
  end

  def get_post(id, current_user, adaptee) do
    case adaptee.get_post(id, current_user) do
      nil -> nil
      db_post -> to_domain(db_post)
    end
  end

  @doc "Converts a Postgres post entity (with its associations preloaded) into the pure domain entity."
  def to_domain(db_post) do
    %DomainPost{
      id: db_post.id,
      thinking: db_post.thinking,
      like_count: db_post.like_count,
      liked_by_user: db_post.liked_by_user,
      comment_count: db_post.comment_count,
      book: BookRepositoryAdapter.to_domain(db_post.book),
      passage: PassageRepositoryAdapter.to_domain(db_post.passage),
      keywords: Enum.map(db_post.keywords, &KeywordRepositoryAdapter.to_domain/1),
      user: UserRepositoryAdapter.to_domain(db_post.user),
      inserted_at: db_post.inserted_at,
      updated_at: db_post.updated_at
    }
  end
end
