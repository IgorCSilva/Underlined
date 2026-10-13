defmodule Api.Usecases.Club.SetCurrentClubChapter.SetCurrentClubChapterUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Club.SetCurrentClubChapter.SetCurrentClubChapterUsecase`.
  """

  alias Api.Domain.User

  @enforce_keys [:user, :club_id, :chapter_id]
  defstruct [:user, :club_id, :chapter_id]

  @type t :: %__MODULE__{user: User.t(), club_id: Ecto.UUID.t(), chapter_id: Ecto.UUID.t()}
end
