defmodule Api.Usecases.Club.ListClubs.ListClubsUsecase do
  @moduledoc """
  Lists the most recently created clubs across every book, annotated for
  the current viewer.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Club.ListClubs.ListClubsUsecaseDto

  defstruct [:repository]

  def call(%ListClubsUsecaseDto{current_user: current_user}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.list_clubs(current_user, adaptee)
  end
end
