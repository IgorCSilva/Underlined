defmodule Api.Infrastructure.Repository.Club.Postgres.ClubReadingProgressRepository do
  @moduledoc """
  Postgres-backed data access for a reader's own progress through a
  club's reading schedule. Reading or setting your own progress needs no
  club membership — it's personal bookkeeping, not a club action.
  """

  import Ecto.Query, warn: false

  alias Api.Infrastructure.Repository.Club.Postgres.{Club, ClubChapter, ClubReadingProgress}
  alias Api.Repo

  @doc """
  Sets `user`'s furthest-read chapter in `club_id` to `chapter_id` (or
  `nil`, resetting to "not started yet"). Upserts the one row per
  club+user.
  """
  def set_progress(user, club_id, chapter_id) do
    with %Club{} = _club <- Repo.get(Club, club_id) || {:error, :not_found},
         :ok <- authorize_chapter(club_id, chapter_id) do
      existing = Repo.get_by(ClubReadingProgress, club_id: club_id, user_id: user.id)

      (existing || %ClubReadingProgress{})
      |> ClubReadingProgress.changeset(%{
        "club_id" => club_id,
        "user_id" => user.id,
        "chapter_id" => chapter_id
      })
      |> Repo.insert_or_update()
      |> case do
        {:ok, progress} -> {:ok, Repo.preload(progress, :chapter)}
        {:error, changeset} -> {:error, changeset}
      end
    end
  end

  @doc "The caller's own reading progress for `club_id` — a `nil` chapter means they haven't started."
  def get_progress(user, club_id) do
    with %Club{} = _club <- Repo.get(Club, club_id) || {:error, :not_found} do
      progress =
        Repo.get_by(ClubReadingProgress, club_id: club_id, user_id: user.id) ||
          %ClubReadingProgress{club_id: club_id, user_id: user.id, chapter_id: nil}

      {:ok, Repo.preload(progress, :chapter)}
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
