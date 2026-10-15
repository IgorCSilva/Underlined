defmodule Api.Usecases.Club.ListClubsForBook.ListClubsForBookUsecase do
  @moduledoc """
  Lists every club scoped to a book, annotated for the current viewer.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Club.ListClubsForBook.ListClubsForBookUsecaseDto

  defstruct [:repository]

  def call(%ListClubsForBookUsecaseDto{book_id: book_id, current_user: current_user}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.list_clubs_for_book(book_id, current_user, adaptee)
  end
end
