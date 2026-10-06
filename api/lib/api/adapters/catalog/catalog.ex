defmodule Api.Adapters.Catalog do
  @moduledoc """
  Facade over the book catalog usecases.

  Callers build the DTO the target usecase expects and pass it in; this
  module only routes each DTO to its usecase.
  """

  alias Api.Usecases.Book.AddBook.AddBookUsecase
  alias Api.Usecases.Book.GetBook.GetBookUsecase
  alias Api.Usecases.Book.GetBookPage.GetBookPageUsecase
  alias Api.Usecases.Book.ListBooks.ListBooksUsecase

  def list_books(dto) do
    ListBooksUsecase.call(dto, %ListBooksUsecase{repository: book_repository()})
  end

  def get_book(dto) do
    GetBookUsecase.call(dto, %GetBookUsecase{repository: book_repository()})
  end

  def get_book_page(dto) do
    GetBookPageUsecase.call(dto, %GetBookPageUsecase{repository: book_repository()})
  end

  def add_book(dto) do
    AddBookUsecase.call(dto, %AddBookUsecase{repository: book_repository()})
  end

  defp book_repository, do: Application.get_env(:api, :book_repository) |> Map.new()
end
