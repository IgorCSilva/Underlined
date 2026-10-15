defmodule Api.Domain.ClubChapter do
  @moduledoc """
  Pure business-rule entity for one segment of a club's reading schedule
  (a "chapter" in the roadmap's default wording, but the club itself
  chooses the word — see `Api.Domain.Club.chapter_unit_label`). Holds no
  knowledge of Ecto, Postgres, or any other persistence detail.
  """

  defstruct [:id, :position, :label, :current, :inserted_at, :updated_at]

  @type t :: %__MODULE__{
          id: String.t(),
          position: integer(),
          label: String.t(),
          current: boolean(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }
end
