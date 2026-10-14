defmodule Api.Usecases.Club.SetClubReadingProgress.SetClubReadingProgressUsecase do
  @moduledoc """
  Sets the caller's own furthest-read chapter in a club (or `nil`,
  resetting to "not started yet"). Needs no club membership — it's
  personal bookkeeping, not a club action.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Club.SetClubReadingProgress.SetClubReadingProgressUsecaseDto

  defstruct [:repository]

  def call(
        %SetClubReadingProgressUsecaseDto{user: user, club_id: club_id, chapter_id: chapter_id},
        %__MODULE__{repository: %{adapter: adapter, adaptee: adaptee}}
      ) do
    adapter.set_progress(user, club_id, chapter_id, adaptee)
  end
end
