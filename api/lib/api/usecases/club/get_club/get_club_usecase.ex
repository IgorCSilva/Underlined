defmodule Api.Usecases.Club.GetClub.GetClubUsecase do
  @moduledoc """
  Looks up a club by id, annotated for the current viewer.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Club.GetClub.GetClubUsecaseDto

  defstruct [:repository]

  def call(%GetClubUsecaseDto{id: id, current_user: current_user}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.get_club(id, current_user, adaptee)
  end
end
