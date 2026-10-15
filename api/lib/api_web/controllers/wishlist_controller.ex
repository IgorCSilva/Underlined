defmodule ApiWeb.WishlistController do
  use ApiWeb, :controller

  alias Api.Adapters.Wishlists
  alias Api.Usecases.Wishlist.AddToWishlist.AddToWishlistUsecaseDto
  alias Api.Usecases.Wishlist.RemoveFromWishlist.RemoveFromWishlistUsecaseDto

  action_fallback ApiWeb.FallbackController

  def create(conn, %{"book_id" => book_id}) do
    with {:ok, result} <-
           Wishlists.add_to_wishlist(%AddToWishlistUsecaseDto{
             user: current_user(conn),
             book_id: book_id
           }) do
      render(conn, :show, wishlist_item: result)
    end
  end

  def delete(conn, %{"book_id" => book_id}) do
    with {:ok, result} <-
           Wishlists.remove_from_wishlist(%RemoveFromWishlistUsecaseDto{
             user: current_user(conn),
             book_id: book_id
           }) do
      render(conn, :show, wishlist_item: result)
    end
  end

  defp current_user(conn), do: Api.Infrastructure.Guardian.Plug.current_resource(conn)
end
