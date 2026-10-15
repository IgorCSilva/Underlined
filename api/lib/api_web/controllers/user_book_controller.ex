defmodule ApiWeb.UserBookController do
  use ApiWeb, :controller

  alias Api.Adapters.UserBooks
  alias Api.Usecases.UserBook.SetUserBookStatus.SetUserBookStatusUsecaseDto

  action_fallback ApiWeb.FallbackController

  def update(conn, %{"book_id" => book_id, "shelf" => %{"status" => status}}) do
    with {:ok, user_book} <-
           UserBooks.set_user_book_status(%SetUserBookStatusUsecaseDto{
             user: current_user(conn),
             book_id: book_id,
             status: status
           }) do
      render(conn, :show, user_book: user_book)
    end
  end

  defp current_user(conn), do: Api.Infrastructure.Guardian.Plug.current_resource(conn)
end
