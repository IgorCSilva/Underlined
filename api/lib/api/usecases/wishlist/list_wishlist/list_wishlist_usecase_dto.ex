defmodule Api.Usecases.Wishlist.ListWishlist.ListWishlistUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Wishlist.ListWishlist.ListWishlistUsecase`.
  """

  @enforce_keys [:user_id]
  defstruct [:user_id]

  @type t :: %__MODULE__{user_id: Ecto.UUID.t()}
end
