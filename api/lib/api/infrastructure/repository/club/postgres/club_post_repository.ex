defmodule Api.Infrastructure.Repository.Club.Postgres.ClubPostRepository do
  @moduledoc """
  Postgres-backed data access for a club's discussion posts. Posting is
  restricted to the club's own members (reading is open to everyone, same
  as the club itself) — unlike `Api.Infrastructure.Repository.Post.Postgres.PostRepository`,
  there's no passage/keywords here, only a body and an optional chapter tag.
  """

  import Ecto.Query, warn: false

  alias Api.Infrastructure.Repository.Club.Postgres.{Club, ClubChapter, ClubMembership, ClubPost}
  alias Api.Repo

  @doc """
  Creates a discussion post in `club_id`, tagged to `attrs["chapter_id"]`
  when given. Only an existing member of the club may post.
  """
  def create_post(user, club_id, attrs) do
    with %Club{} = club <- Repo.get(Club, club_id) || {:error, :not_found},
         :ok <- authorize_member(club.id, user),
         :ok <- authorize_chapter(club.id, attrs["chapter_id"]) do
      %ClubPost{}
      |> ClubPost.changeset(%{
        "club_id" => club.id,
        "chapter_id" => attrs["chapter_id"],
        "user_id" => user.id,
        "body" => attrs["body"]
      })
      |> Repo.insert()
      |> case do
        {:ok, post} -> {:ok, Repo.preload(post, [:user, :chapter])}
        {:error, changeset} -> {:error, changeset}
      end
    end
  end

  @doc """
  All discussion posts for a club: general (untagged) posts first, then
  each chapter's posts in schedule order, oldest post first within each
  group — the grouping itself is left to the caller to render as headings.
  """
  def list_posts(club_id) do
    with %Club{} = _club <- Repo.get(Club, club_id) || {:error, :not_found} do
      posts =
        ClubPost
        |> where([p], p.club_id == ^club_id)
        |> order_by(asc: :inserted_at)
        |> Repo.all()
        |> Repo.preload([:user, :chapter])
        |> Enum.sort_by(&{chapter_sort_key(&1), &1.inserted_at})

      {:ok, posts}
    end
  end

  defp chapter_sort_key(%ClubPost{chapter: nil}), do: -1
  defp chapter_sort_key(%ClubPost{chapter: %ClubChapter{position: position}}), do: position

  defp authorize_member(club_id, user) do
    if Repo.exists?(
         from m in ClubMembership, where: m.club_id == ^club_id and m.user_id == ^user.id
       ) do
      :ok
    else
      {:error, :forbidden}
    end
  end

  defp authorize_chapter(_club_id, nil), do: :ok

  defp authorize_chapter(club_id, chapter_id) do
    case Ecto.UUID.cast(chapter_id) do
      {:ok, uuid} ->
        if Repo.exists?(from c in ClubChapter, where: c.id == ^uuid and c.club_id == ^club_id) do
          :ok
        else
          {:error, :invalid_chapter}
        end

      :error ->
        {:error, :invalid_chapter}
    end
  end
end
