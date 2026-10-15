defmodule Api.Usecases.Club.UpdateClubChapter.UpdateClubChapterUsecase do
  @moduledoc """
  Edits an existing chapter's label and/or target date. Only the club's
  creator may do this — enforced by the repository.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Club.UpdateClubChapter.UpdateClubChapterUsecaseDto

  defstruct [:repository]

  def call(
        %UpdateClubChapterUsecaseDto{
          user: user,
          club_id: club_id,
          chapter_id: chapter_id,
          attrs: attrs
        },
        %__MODULE__{repository: %{adapter: adapter, adaptee: adaptee}}
      ) do
    adapter.update_chapter(user, club_id, chapter_id, attrs, adaptee)
  end
end
