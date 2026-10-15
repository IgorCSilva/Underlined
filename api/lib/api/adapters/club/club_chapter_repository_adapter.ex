defmodule Api.Adapters.Club.ClubChapterRepositoryAdapter do
  @moduledoc """
  Adapts a club-chapter repository (the adaptee) to the domain: calls it
  for the database entity/entities, then converts the result(s) into the
  pure Api.Domain.ClubChapter business entity.
  """

  alias Api.Domain.ClubChapter, as: DomainClubChapter

  def create_chapter(user, club_id, attrs, adaptee) do
    case adaptee.create_chapter(user, club_id, attrs) do
      {:ok, db_chapter} -> {:ok, to_domain(db_chapter)}
      {:error, reason} -> {:error, reason}
    end
  end

  def list_chapters(club_id, adaptee) do
    case adaptee.list_chapters(club_id) do
      {:ok, db_chapters} -> {:ok, Enum.map(db_chapters, &to_domain/1)}
      {:error, reason} -> {:error, reason}
    end
  end

  def set_current_chapter(user, club_id, chapter_id, adaptee) do
    case adaptee.set_current_chapter(user, club_id, chapter_id) do
      {:ok, db_chapter} -> {:ok, to_domain(db_chapter)}
      {:error, reason} -> {:error, reason}
    end
  end

  def update_chapter(user, club_id, chapter_id, attrs, adaptee) do
    case adaptee.update_chapter(user, club_id, chapter_id, attrs) do
      {:ok, db_chapter} -> {:ok, to_domain(db_chapter)}
      {:error, reason} -> {:error, reason}
    end
  end

  def move_chapter(user, club_id, chapter_id, direction, adaptee) do
    case adaptee.move_chapter(user, club_id, chapter_id, direction) do
      {:ok, db_chapter} -> {:ok, to_domain(db_chapter)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "Converts a Postgres club-chapter entity into the pure domain entity."
  def to_domain(db_chapter) do
    %DomainClubChapter{
      id: db_chapter.id,
      position: db_chapter.position,
      label: db_chapter.label,
      current: db_chapter.current,
      target_date: db_chapter.target_date,
      inserted_at: db_chapter.inserted_at,
      updated_at: db_chapter.updated_at
    }
  end
end
