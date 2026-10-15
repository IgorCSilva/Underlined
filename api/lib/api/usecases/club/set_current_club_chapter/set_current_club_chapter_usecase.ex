defmodule Api.Usecases.Club.SetCurrentClubChapter.SetCurrentClubChapterUsecase do
  @moduledoc """
  Advances (or rewinds) a club's reading progress by marking one of its
  existing chapters as the current one. Only the club's creator may do
  this — enforced by the repository.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Club.SetCurrentClubChapter.SetCurrentClubChapterUsecaseDto

  defstruct [:repository]

  def call(
        %SetCurrentClubChapterUsecaseDto{user: user, club_id: club_id, chapter_id: chapter_id},
        %__MODULE__{repository: %{adapter: adapter, adaptee: adaptee}}
      ) do
    adapter.set_current_chapter(user, club_id, chapter_id, adaptee)
  end
end
