defmodule Api.Adapters.UserBooks do
  @moduledoc """
  Facade over the bookcase usecases: shelve a book under a reading
  status, and list everything on a user's bookcase.

  Callers build the DTO the target usecase expects and pass it in; this
  module only routes each DTO to its usecase.
  """

  alias Api.Usecases.UserBook.ListUserBooks.ListUserBooksUsecase
  alias Api.Usecases.UserBook.SetUserBookStatus.SetUserBookStatusUsecase

  def set_user_book_status(dto) do
    SetUserBookStatusUsecase.call(dto, %SetUserBookStatusUsecase{
      repository: user_book_repository()
    })
  end

  def list_user_books(dto) do
    ListUserBooksUsecase.call(dto, %ListUserBooksUsecase{repository: user_book_repository()})
  end

  defp user_book_repository, do: Application.get_env(:api, :user_book_repository) |> Map.new()
end
