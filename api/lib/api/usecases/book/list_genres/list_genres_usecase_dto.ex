defmodule Api.Usecases.Book.ListGenres.ListGenresUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Book.ListGenres.ListGenresUsecase`. Takes no
  parameters — it lists every distinct genre already in the catalog.
  """

  defstruct []

  @type t :: %__MODULE__{}
end
