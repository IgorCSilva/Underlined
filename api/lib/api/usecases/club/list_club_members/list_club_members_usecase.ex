defmodule Api.Usecases.Club.ListClubMembers.ListClubMembersUsecase do
  @moduledoc """
  Lists every member of a club, earliest joiner first.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Club.ListClubMembers.ListClubMembersUsecaseDto

  defstruct [:repository]

  def call(%ListClubMembersUsecaseDto{club_id: club_id}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.list_members(club_id, adaptee)
  end
end
