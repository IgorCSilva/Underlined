defmodule Api.Adapters.Wishlists do
  @moduledoc """
  Facade over the wishlist usecases: want a book, stop wanting it, and
  list everything a user has wishlisted.

  Callers build the DTO the target usecase expects and pass it in; this
  module only routes each DTO to its usecase.
  """

  alias Api.Usecases.Wishlist.AddToWishlist.AddToWishlistUsecase
  alias Api.Usecases.Wishlist.ListWishlist.ListWishlistUsecase
  alias Api.Usecases.Wishlist.RemoveFromWishlist.RemoveFromWishlistUsecase

  def add_to_wishlist(dto) do
    AddToWishlistUsecase.call(dto, %AddToWishlistUsecase{repository: wishlist_repository()})
  end

  def remove_from_wishlist(dto) do
    RemoveFromWishlistUsecase.call(dto, %RemoveFromWishlistUsecase{
      repository: wishlist_repository()
    })
  end

  def list_wishlist(dto) do
    ListWishlistUsecase.call(dto, %ListWishlistUsecase{repository: wishlist_repository()})
  end

  defp wishlist_repository, do: Application.get_env(:api, :wishlist_repository) |> Map.new()
end
