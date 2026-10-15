defmodule Api.Usecases.Club.GetClubReadingProgress.GetClubReadingProgressUsecase do
  @moduledoc """
  Fetches the caller's own reading progress in a club — a `nil` chapter
  means they haven't started.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Club.GetClubReadingProgress.GetClubReadingProgressUsecaseDto

  defstruct [:repository]

  def call(%GetClubReadingProgressUsecaseDto{user: user, club_id: club_id}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.get_progress(user, club_id, adaptee)
  end
end
