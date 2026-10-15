defmodule Api.Usecases.UserBook.ListUserBooks.ListUserBooksUsecase do
  @moduledoc """
  Every book on a user's bookcase, each with its shelved status
  (to_read/reading/read) — the whole bookcase at once, so the caller can
  split it into "All"/per-status tabs without a separate request per tab.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.UserBook.ListUserBooks.ListUserBooksUsecaseDto

  defstruct [:repository]

  def call(%ListUserBooksUsecaseDto{user_id: user_id}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.list_user_books(user_id, adaptee)
  end
end
