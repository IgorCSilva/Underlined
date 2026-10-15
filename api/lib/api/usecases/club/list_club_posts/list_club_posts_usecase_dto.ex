defmodule Api.Usecases.Club.ListClubPosts.ListClubPostsUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Club.ListClubPosts.ListClubPostsUsecase`.
  """

  @enforce_keys [:club_id]
  defstruct [:club_id, :current_user]

  @type t :: %__MODULE__{
          club_id: Ecto.UUID.t(),
          current_user: Api.Domain.User.t() | nil
        }
end
