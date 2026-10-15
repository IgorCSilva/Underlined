defmodule Api.Usecases.Club.CreateClubChapter.CreateClubChapterUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Club.CreateClubChapter.CreateClubChapterUsecase`.
  """

  alias Api.Domain.User

  @enforce_keys [:user, :club_id, :attrs]
  defstruct [:user, :club_id, :attrs]

  @type t :: %__MODULE__{user: User.t(), club_id: Ecto.UUID.t(), attrs: map()}
end
