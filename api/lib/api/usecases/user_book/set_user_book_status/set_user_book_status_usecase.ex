defmodule Api.Usecases.UserBook.SetUserBookStatus.SetUserBookStatusUsecase do
  @moduledoc """
  Shelves a book onto the caller's bookcase under one of the three
  reading statuses (to_read/reading/read), or moves it to a different
  one if it's already shelved. Upserts the one row per user+book.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.UserBook.SetUserBookStatus.SetUserBookStatusUsecaseDto

  defstruct [:repository]

  def call(
        %SetUserBookStatusUsecaseDto{user: user, book_id: book_id, status: status},
        %__MODULE__{repository: %{adapter: adapter, adaptee: adaptee}}
      ) do
    adapter.set_status(user, book_id, status, adaptee)
  end
end
