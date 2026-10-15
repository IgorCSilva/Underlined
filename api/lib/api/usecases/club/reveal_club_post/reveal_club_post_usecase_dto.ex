defmodule Api.Usecases.Club.RevealClubPost.RevealClubPostUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Club.RevealClubPost.RevealClubPostUsecase`.
  """

  @enforce_keys [:post_id]
  defstruct [:post_id]

  @type t :: %__MODULE__{post_id: Ecto.UUID.t()}
end
