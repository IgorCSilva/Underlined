defmodule Api.Usecases.Club.CreateClubComment.CreateClubCommentUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Club.CreateClubComment.CreateClubCommentUsecase`.
  """

  alias Api.Domain.User

  @enforce_keys [:user, :club_post_id, :attrs]
  defstruct [:user, :club_post_id, :attrs]

  @type t :: %__MODULE__{user: User.t(), club_post_id: Ecto.UUID.t(), attrs: map()}
end
