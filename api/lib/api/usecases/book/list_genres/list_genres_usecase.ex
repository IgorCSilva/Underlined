defmodule Api.Usecases.Book.ListGenres.ListGenresUsecase do
  @moduledoc """
  Lists every distinct genre already in the catalog, so the add-book form
  can offer autocomplete without the list fragmenting into near-duplicates.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  defstruct [:repository]

  def call(_dto, %__MODULE__{repository: %{adapter: adapter, adaptee: adaptee}}) do
    adapter.list_genres(adaptee)
  end
end
