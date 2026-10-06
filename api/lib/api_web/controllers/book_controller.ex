defmodule ApiWeb.BookController do
  use ApiWeb, :controller

  alias Api.Adapters.Catalog
  alias Api.Usecases.Book.AddBook.AddBookUsecaseDto
  alias Api.Usecases.Book.GetBook.GetBookUsecaseDto
  alias Api.Usecases.Book.GetBookPage.GetBookPageUsecaseDto
  alias Api.Usecases.Book.ListBooks.ListBooksUsecaseDto

  action_fallback ApiWeb.FallbackController

  def index(conn, params) do
    books = Catalog.list_books(%ListBooksUsecaseDto{query: params["q"]})
    render(conn, :index, books: books)
  end

  def show(conn, %{"id" => id}) do
    case Catalog.get_book(%GetBookUsecaseDto{id: id}) do
      nil -> {:error, :not_found}
      book -> render(conn, :show, book: book)
    end
  end

  def page(conn, %{"id" => id} = params) do
    with {:ok, page} <-
           Catalog.get_book_page(%GetBookPageUsecaseDto{
             id: id,
             before: params["before"],
             current_user: current_user(conn)
           }) do
      render(conn, :page, page: page)
    end
  end

  def create(conn, %{"book" => book_params}) do
    with {:ok, book} <- Catalog.add_book(%AddBookUsecaseDto{attrs: book_params}) do
      render(conn, :show, book: book)
    end
  end

  defp current_user(conn), do: Api.Infrastructure.Guardian.Plug.current_resource(conn)
end
