defmodule Api.Usecases.Club.MoveClubChapter.MoveClubChapterUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Club.MoveClubChapter.MoveClubChapterUsecase`.
  `direction` is `"up"` (earlier position) or `"down"` (later position).
  """

  alias Api.Domain.User

  @enforce_keys [:user, :club_id, :chapter_id, :direction]
  defstruct [:user, :club_id, :chapter_id, :direction]

  @type t :: %__MODULE__{
          user: User.t(),
          club_id: Ecto.UUID.t(),
          chapter_id: Ecto.UUID.t(),
          direction: String.t()
        }
end
