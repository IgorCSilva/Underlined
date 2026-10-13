defmodule Api.Usecases.Club.CreateClubPost.CreateClubPostUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Club.CreateClubPost.CreateClubPostUsecase`.
  """

  alias Api.Domain.User

  @enforce_keys [:user, :club_id, :attrs]
  defstruct [:user, :club_id, :attrs]

  @type t :: %__MODULE__{user: User.t(), club_id: Ecto.UUID.t(), attrs: map()}
end
