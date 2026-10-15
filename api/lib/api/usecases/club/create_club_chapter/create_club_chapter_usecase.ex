defmodule Api.Usecases.Club.CreateClubChapter.CreateClubChapterUsecase do
  @moduledoc """
  Appends a new chapter to a club's reading schedule. Only the club's
  creator may do this — enforced by the repository, since it already
  holds the club's `creator_id`.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Club.CreateClubChapter.CreateClubChapterUsecaseDto

  defstruct [:repository]

  def call(%CreateClubChapterUsecaseDto{user: user, club_id: club_id, attrs: attrs}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.create_chapter(user, club_id, attrs, adaptee)
  end
end
