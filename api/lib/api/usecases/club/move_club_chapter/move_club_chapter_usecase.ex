defmodule Api.Usecases.Club.MoveClubChapter.MoveClubChapterUsecase do
  @moduledoc """
  Reorders a club's reading schedule by swapping one chapter with its
  immediate neighbor. Only the club's creator may do this — enforced by
  the repository.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Club.MoveClubChapter.MoveClubChapterUsecaseDto

  defstruct [:repository]

  def call(
        %MoveClubChapterUsecaseDto{
          user: user,
          club_id: club_id,
          chapter_id: chapter_id,
          direction: direction
        },
        %__MODULE__{repository: %{adapter: adapter, adaptee: adaptee}}
      ) do
    adapter.move_chapter(user, club_id, chapter_id, direction, adaptee)
  end
end
