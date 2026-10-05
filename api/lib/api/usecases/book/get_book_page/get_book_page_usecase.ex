defmodule Api.Usecases.Book.GetBookPage.GetBookPageUsecase do
  @moduledoc """
  A book's stats (posts/readers) and a page of posts about it, newest
  first.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Book.GetBookPage.GetBookPageUsecaseDto

  defstruct [:repository]

  def call(
        %GetBookPageUsecaseDto{id: id, before: before, current_user: current_user},
        %__MODULE__{repository: %{adapter: adapter, adaptee: adaptee}}
      ) do
    adapter.get_book_page(id, before, current_user, adaptee)
  end
end
