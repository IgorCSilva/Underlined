defmodule Api.Usecases.Club.UpdateClubChapter.UpdateClubChapterUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Club.UpdateClubChapter.UpdateClubChapterUsecase`.
  """

  alias Api.Domain.User

  @enforce_keys [:user, :club_id, :chapter_id, :attrs]
  defstruct [:user, :club_id, :chapter_id, :attrs]

  @type t :: %__MODULE__{
          user: User.t(),
          club_id: Ecto.UUID.t(),
          chapter_id: Ecto.UUID.t(),
          attrs: map()
        }
end
