defmodule Api.Usecases.Club.ListClubChapters.ListClubChaptersUsecase do
  @moduledoc """
  Lists a club's reading-schedule chapters, oldest first, each flagged
  with whether it's the club's current one. Open to everyone, same as the
  club itself.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Club.ListClubChapters.ListClubChaptersUsecaseDto

  defstruct [:repository]

  def call(%ListClubChaptersUsecaseDto{club_id: club_id}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.list_chapters(club_id, adaptee)
  end
end
