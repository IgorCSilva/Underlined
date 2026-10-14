defmodule Api.Adapters.Club.ClubReadingProgressRepositoryAdapter do
  @moduledoc """
  Adapts a club-reading-progress repository (the adaptee) to the domain:
  calls it for the database entity, then converts the result into the
  pure Api.Domain.ClubReadingProgress business entity.
  """

  alias Api.Adapters.Club.ClubChapterRepositoryAdapter
  alias Api.Domain.ClubReadingProgress, as: DomainClubReadingProgress

  def set_progress(user, club_id, chapter_id, adaptee) do
    case adaptee.set_progress(user, club_id, chapter_id) do
      {:ok, db_progress} -> {:ok, to_domain(db_progress)}
      {:error, reason} -> {:error, reason}
    end
  end

  def get_progress(user, club_id, adaptee) do
    case adaptee.get_progress(user, club_id) do
      {:ok, db_progress} -> {:ok, to_domain(db_progress)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "Converts a Postgres club-reading-progress entity (with :chapter preloaded) into the pure domain entity."
  def to_domain(db_progress) do
    %DomainClubReadingProgress{chapter: chapter_to_domain(db_progress.chapter)}
  end

  defp chapter_to_domain(nil), do: nil
  defp chapter_to_domain(db_chapter), do: ClubChapterRepositoryAdapter.to_domain(db_chapter)
end
