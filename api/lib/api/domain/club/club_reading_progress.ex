defmodule Api.Domain.ClubReadingProgress do
  @moduledoc """
  Pure business-rule entity for one reader's own progress through a
  club's reading schedule: the furthest chapter they've read, with `nil`
  meaning they haven't started. Used to decide which chapter-tagged
  discussion stays spoiler-blocked for them. Holds no knowledge of Ecto,
  Postgres, or any other persistence detail.
  """

  defstruct [:chapter]

  @type t :: %__MODULE__{chapter: Api.Domain.ClubChapter.t() | nil}
end
