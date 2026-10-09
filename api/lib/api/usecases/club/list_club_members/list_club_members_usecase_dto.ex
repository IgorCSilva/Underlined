defmodule Api.Usecases.Club.ListClubMembers.ListClubMembersUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Club.ListClubMembers.ListClubMembersUsecase`.
  """

  @enforce_keys [:club_id]
  defstruct [:club_id]

  @type t :: %__MODULE__{club_id: Ecto.UUID.t()}
end
