defmodule Api.Usecases.Wishlist.AddToWishlist.AddToWishlistUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Wishlist.AddToWishlist.AddToWishlistUsecase`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User

  @enforce_keys [:user, :book_id]
  defstruct [:user, :book_id]

  @type t :: %__MODULE__{user: %User{}, book_id: Ecto.UUID.t()}
end
