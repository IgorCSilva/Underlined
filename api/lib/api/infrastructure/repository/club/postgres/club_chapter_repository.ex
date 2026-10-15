defmodule Api.Infrastructure.Repository.Club.Postgres.ClubChapterRepository do
  @moduledoc """
  Postgres-backed data access for a club's reading schedule (its ordered
  chapters, and which one is "current"). Managing the schedule — adding a
  chapter, choosing the unit word ("Chapter", "Letter", "Date", ...),
  advancing the current chapter — is restricted to the club's creator;
  reading it is open to everyone, same as the club itself.
  """

  import Ecto.Query, warn: false

  alias Api.Infrastructure.Repository.Club.Postgres.{Club, ClubChapter}
  alias Api.Repo

  @doc """
  Appends a new chapter to the club's schedule. `attrs["chapter_unit_label"]`
  is optional — when present, it also renames the word the club uses for
  its schedule segments (e.g. switching from "Chapter" to "Letter").
  """
  def create_chapter(user, club_id, attrs) do
    with %Club{} = club <- Repo.get(Club, club_id) || {:error, :not_found},
         :ok <- authorize_creator(club, user) do
      next_position = next_position(club_id)

      multi =
        Ecto.Multi.new()
        |> Ecto.Multi.insert(
          :chapter,
          ClubChapter.changeset(%ClubChapter{}, %{
            "club_id" => club_id,
            "position" => next_position,
            "label" => attrs["label"],
            "target_date" => attrs["target_date"]
          })
        )
        |> Ecto.Multi.run(:club, fn repo, _changes ->
          maybe_update_unit_label(repo, club, attrs["chapter_unit_label"])
        end)

      case Repo.transaction(multi) do
        {:ok, %{chapter: chapter}} -> {:ok, %{chapter | current: false}}
        {:error, :chapter, changeset, _changes} -> {:error, changeset}
      end
    end
  end

  @doc "Chapters for a club, oldest (lowest position) first, each flagged with whether it's the club's current one."
  def list_chapters(club_id) do
    with %Club{} = club <- Repo.get(Club, club_id) || {:error, :not_found} do
      chapters =
        ClubChapter
        |> where([c], c.club_id == ^club_id)
        |> order_by(asc: :position)
        |> Repo.all()
        |> Enum.map(&%{&1 | current: &1.id == club.current_chapter_id})

      {:ok, chapters}
    end
  end

  @doc "Sets `chapter_id` as the club's current chapter. The chapter must belong to this club."
  def set_current_chapter(user, club_id, chapter_id) do
    with %Club{} = club <- Repo.get(Club, club_id) || {:error, :not_found},
         :ok <- authorize_creator(club, user),
         {:ok, uuid} <- cast_uuid(chapter_id),
         %ClubChapter{} = chapter <-
           Repo.get_by(ClubChapter, id: uuid, club_id: club_id) ||
             {:error, :invalid_chapter} do
      case club
           |> Club.chapter_settings_changeset(%{"current_chapter_id" => chapter.id})
           |> Repo.update() do
        {:ok, _club} -> {:ok, %{chapter | current: true}}
        {:error, changeset} -> {:error, changeset}
      end
    end
  end

  @doc "Edits an existing chapter's label and/or target date. Only the club's creator may do this."
  def update_chapter(user, club_id, chapter_id, attrs) do
    with %Club{} = club <- Repo.get(Club, club_id) || {:error, :not_found},
         :ok <- authorize_creator(club, user),
         {:ok, uuid} <- cast_uuid(chapter_id),
         %ClubChapter{} = chapter <-
           Repo.get_by(ClubChapter, id: uuid, club_id: club_id) ||
             {:error, :invalid_chapter} do
      case chapter
           |> ClubChapter.edit_changeset(attrs)
           |> Repo.update() do
        {:ok, updated} -> {:ok, %{updated | current: updated.id == club.current_chapter_id}}
        {:error, changeset} -> {:error, changeset}
      end
    end
  end

  @doc """
  Swaps a chapter with its immediate neighbor in the schedule ("up" = earlier
  position, "down" = later). Only the club's creator may do this. The swap
  passes the moving chapter through a temporary position so neither update
  collides with the unique `[club_id, position]` index.
  """
  def move_chapter(user, club_id, chapter_id, direction) do
    with %Club{} = club <- Repo.get(Club, club_id) || {:error, :not_found},
         :ok <- authorize_creator(club, user),
         {:ok, uuid} <- cast_uuid(chapter_id),
         %ClubChapter{} = chapter <-
           Repo.get_by(ClubChapter, id: uuid, club_id: club_id) ||
             {:error, :invalid_chapter},
         %ClubChapter{} = neighbor <-
           find_neighbor(club_id, chapter, direction) || {:error, :no_neighbor} do
      chapter_position = chapter.position
      neighbor_position = neighbor.position

      multi =
        Ecto.Multi.new()
        |> Ecto.Multi.update(:parked, ClubChapter.position_changeset(chapter, %{"position" => -1}))
        |> Ecto.Multi.update(:neighbor, fn _ ->
          ClubChapter.position_changeset(neighbor, %{"position" => chapter_position})
        end)
        |> Ecto.Multi.update(:chapter, fn _ ->
          ClubChapter.position_changeset(chapter, %{"position" => neighbor_position})
        end)

      case Repo.transaction(multi) do
        {:ok, %{chapter: updated}} ->
          {:ok, %{updated | current: updated.id == club.current_chapter_id}}

        {:error, _step, changeset, _changes} ->
          {:error, changeset}
      end
    end
  end

  defp find_neighbor(club_id, %ClubChapter{position: position}, "up") do
    ClubChapter
    |> where([c], c.club_id == ^club_id and c.position < ^position)
    |> order_by(desc: :position)
    |> limit(1)
    |> Repo.one()
  end

  defp find_neighbor(club_id, %ClubChapter{position: position}, "down") do
    ClubChapter
    |> where([c], c.club_id == ^club_id and c.position > ^position)
    |> order_by(asc: :position)
    |> limit(1)
    |> Repo.one()
  end

  defp find_neighbor(_club_id, _chapter, _direction), do: nil

  defp cast_uuid(value) do
    case Ecto.UUID.cast(value) do
      {:ok, uuid} -> {:ok, uuid}
      :error -> {:error, :invalid_chapter}
    end
  end

  defp next_position(club_id) do
    (Repo.aggregate(where(ClubChapter, club_id: ^club_id), :max, :position) || 0) + 1
  end

  defp maybe_update_unit_label(_repo, club, nil), do: {:ok, club}

  defp maybe_update_unit_label(repo, club, unit_label) do
    club
    |> Club.chapter_settings_changeset(%{"chapter_unit_label" => unit_label})
    |> repo.update()
  end

  defp authorize_creator(%Club{creator_id: creator_id}, %{id: user_id})
       when creator_id == user_id,
       do: :ok

  defp authorize_creator(_club, _user), do: {:error, :forbidden}
end
